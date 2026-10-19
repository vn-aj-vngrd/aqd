import SwiftUI

/// Cut a piece out of its photo: automatic subject detection, then Erase, Restore, Trim sides and zoom
/// for a clean transparent result. Done saves a transparent PNG as the draft photo; the original is kept.
struct PieceCutoutView: View {
    @Bindable var capture: CaptureModel
    var embedding: EmbeddedEditing?
    @Environment(\.dismiss) private var dismiss
    @State private var model: PieceCutoutModel?
    @State private var applying = false
    @State private var error: String?
    @State private var discard = false

    var body: some View {
        if embedding == nil { NavigationStack { content } } else { content }
    }

    private var content: some View {
        Group {
            if let model {
                editor(model)
            } else {
                VStack(spacing: AppSpacing.medium) {
                    SemanticFeedback(role: .warning, message: error ?? "Cutout isn’t available for this photo. Your photo and fields are unchanged.")
                    if embedding == nil { SecondaryAction(title: "Close") { dismiss() } }
                }.padding(AppSpacing.screen).frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(AppTheme.canvas)
        .navigationTitle(embedding == nil ? "Cut out piece" : "Edit photo").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if embedding == nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model?.edited == true { discard = true } else { dismiss() }
                    } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Cancel cutout").disabled(applying)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                ToolbarSaveAction(title: embedding == nil ? "Done" : "Apply", isPending: applying) { apply() }
                    .disabled(model == nil || model.map { [.choosing, .detecting, .unsupported].contains($0.phase) } != false || model?.hasKeptPixels != true || applying)
            }
        }
        .tint(AppTheme.ink)
        .draftDiscardConfirmation(isPresented: $discard, title: "Discard this cutout?", message: "Your photo stays as it was. Original Photos are unchanged.") { dismiss() }
        .onAppear(perform: open)
        .onDisappear { model?.cancel() }
        .onChange(of: model.map { $0.edited || ($0.phase == .ready && !$0.hasSavedCutout) } ?? false) { _, value in embedding?.dirty(value) }
    }

    private func finish() { if let embedding { embedding.applied() } else { dismiss() } }

    private func open() {
        guard model == nil else { return }
        do {
            let created = PieceCutoutModel(source: try capture.backgroundInput())
            model = created
            created.start()
        } catch { self.error = "Cutout isn’t available for this photo. Your accepted photo and fields are retained." }
    }

    private func apply() {
        guard let model, !applying else { return }
        applying = true
        Task {
            do {
                let outcome = try await model.finish()
                if capture.acceptBackground(outcome.prepared, input: model.source, crop: outcome.crop, framed: outcome.framed) {
                    capture.photoHints = outcome.hints
                    finish()
                }
                else { error = capture.errorText ?? "The photo changed. Cancel and open the cutout again." }
            } catch {
                self.error = "The cutout couldn’t be prepared. Your photo is unchanged. Try again."
            }
            applying = false
        }
    }

    private func editor(_ model: PieceCutoutModel) -> some View {
        VStack(spacing: AppSpacing.large) {
            CutoutCanvas(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.field))
                .overlay(alignment: .top) { if [.ready, .noSubject, .failed].contains(model.phase) { canvasControls(model) } }
            controls(model)
        }.padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.xSmall).padding(.bottom, AppSpacing.medium)
    }

    @ViewBuilder private func controls(_ model: PieceCutoutModel) -> some View {
        if model.phase == .choosing || model.phase == .unsupported || model.phase == .detecting {
            choice(model)
        } else {
            tools(model)
        }
    }

    /// Nothing runs on its own: the person picks Auto cut out, or starts by hand. Where the iPhone has no subject model, only by hand is offered.
    private func choice(_ model: PieceCutoutModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            if model.phase == .detecting {
                HStack(spacing: AppSpacing.small) {
                    ProgressView().accessibilityHidden(true)
                    Text("Finding the piece…").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Spacer()
                    Button("Cancel") { model.cancel(); model.startByHand() }.frame(minHeight: AppControlMetrics.minimumTarget)
                }.accessibilityElement(children: .combine)
            } else {
                Text(model.phase == .unsupported ? "Automatic cut out isn’t available on this iPhone. Erase the background by hand instead."
                                                 : "Let AQD find the piece, then fine tune it. Or erase the background yourself.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                if model.phase != .unsupported {
                    Button { model.detectAutomatically() } label: {
                        GlassActionLabel(title: "Auto cut out", systemImage: "wand.and.stars", prominent: true, height: AppControlMetrics.actionHeight)
                    }.buttonStyle(.plain).accessibilityIdentifier("cutout.auto")
                }
                Button { model.startByHand() } label: {
                    GlassActionLabel(title: "Cut out by hand", systemImage: "hand.draw", height: AppControlMetrics.actionHeight)
                }.buttonStyle(.plain).accessibilityIdentifier("cutout.manual")
            }
        }
    }

    /// Tool first, then only what that tool needs, then the finishing options as plain rows. Undo, redo, reset and Original float on the photo.
    @ViewBuilder private func tools(_ model: PieceCutoutModel) -> some View {
        let bound = Bindable(model)
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            if let message = hint(for: model) { SemanticFeedback(role: .warning, message: message) }
            if let error { SemanticFeedback(role: .danger, message: error) }
            if (model.phase == .noSubject || model.phase == .failed) && PhotoBackgroundRemover.isSupported {
                Button("Try auto cut out again") { model.detectAutomatically() }.frame(minHeight: AppControlMetrics.minimumTarget)
            }
            HStack(spacing: AppSpacing.small) {
                ForEach(PieceCutoutModel.Tool.allCases, id: \.self) { tool in toolButton(tool, model: model) }
            }
            switch model.tool {
            case .erase, .restore: sliderRow("Brush", value: bound.brushRadius, range: 8...48)
            case .move: sliderRow("Zoom", value: bound.zoom, range: 1...4)
            case .trim: Text("Drag the edges of the frame to trim the sides.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
            Divider().overlay(AppTheme.divider)
            HStack(spacing: AppSpacing.small) {
                Text("Background").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).frame(width: 84, alignment: .leading)
                ForEach(CutoutBackground.allCases, id: \.self) { option in
                    AppChip(title: option.rawValue, isSelected: model.background == option) { model.background = option; model.refresh() }
                }
                Spacer(minLength: 0)
            }
            sliderRow("Softness", value: bound.feather, range: 0...4, onChange: { model.refresh() })
            Toggle("Fit to piece", isOn: bound.fitToPiece).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                .toggleStyle(AppToggleStyle()).frame(minHeight: AppControlMetrics.minimumTarget)
            if model.hasSavedCutout {
                Button("Use original photo") { capture.useOriginalPhoto(); finish() }.frame(minHeight: AppControlMetrics.minimumTarget)
            }
        }
    }

    private func toolButton(_ tool: PieceCutoutModel.Tool, model: PieceCutoutModel) -> some View {
        let selected = model.tool == tool
        return Button { model.tool = tool } label: {
            VStack(spacing: 4) {
                Image(systemName: tool.symbol).font(.body.weight(.medium)).accessibilityHidden(true)
                Text(tool.rawValue).font(AppTypography.metadata).lineLimit(1)
            }.foregroundStyle(selected ? AppTheme.onPrimary : AppTheme.ink)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(selected ? AppTheme.primaryFill : AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : []).accessibilityIdentifier("cutout.tool.\(tool.rawValue)")
    }

    /// Glass controls floating on the photo, so the panel below holds only settings.
    private func canvasControls(_ model: PieceCutoutModel) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            iconButton("arrow.uturn.backward", label: "Undo", enabled: model.canUndo) { model.undo() }
            iconButton("arrow.uturn.forward", label: "Redo", enabled: model.canRedo) { model.redo() }
            iconButton("arrow.counterclockwise", label: "Reset", enabled: model.edited || model.isTrimmed) { model.reset() }
            Spacer()
            Button { model.showOriginal.toggle() } label: {
                // On (showing the original) is a filled charcoal circle, off is plain glass, so the state reads at a glance.
                let on = model.showOriginal
                Image(systemName: on ? "eye.fill" : "eye").foregroundStyle(on ? AppTheme.onPrimary : AppTheme.ink)
                    .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                    .background { if on { Circle().fill(AppTheme.primaryFill) } }
                    .glassControlSurface(Circle())
            }.buttonStyle(.plain).accessibilityLabel("Compare with original").accessibilityValue(model.showOriginal ? "On" : "Off")
        }.padding(AppSpacing.small)
    }

    private func hint(for model: PieceCutoutModel) -> String? {
        switch model.phase {
        case .noSubject: "No piece was found. Try again, or erase the background by hand."
        case .failed: "Auto cut out didn’t work on this photo. Try again, or erase the background by hand."
        default: model.phase == .ready && !model.hasKeptPixels ? "Nothing is kept. Use Restore, or Reset." : nil
        }
    }

    private func sliderRow(_ title: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, onChange: (() -> Void)? = nil) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text(title).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).frame(width: 84, alignment: .leading)
            Slider(value: value, in: range, onEditingChanged: { editing in if !editing { onChange?() } }).accessibilityLabel(title)
        }
    }

    private func iconButton(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).foregroundStyle(AppTheme.ink)
                .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                .glassControlSurface(Circle())
        }.buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.4).accessibilityLabel(label)
    }
}

private struct CutoutCanvas: View {
    @Bindable var model: PieceCutoutModel
    @State private var lastPoint: CGPoint?
    @State private var cursor: CGPoint?
    @State private var panStart: CGSize?
    @State private var trimRecording = false
    @State private var pinchStart: CGFloat?

    var body: some View {
        GeometryReader { proxy in
            let rect = displayRect(in: proxy.size)
            ZStack {
                AppTheme.mediaWash
                layers(rect: rect)
                if model.phase == .detecting {
                    ProgressView("Finding the piece…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.group))
                }
                if model.tool == .trim { trimOverlay(rect: rect) }
                if let cursor, model.tool == .erase || model.tool == .restore {
                    Circle().stroke(AppTheme.ink, lineWidth: 1.5).background(Circle().fill(AppTheme.onMedia.opacity(0.25)))
                        .frame(width: model.brushRadius * 2, height: model.brushRadius * 2).position(cursor).allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(drawGesture(rect: rect), including: model.tool == .trim ? .subviews : .all)
            .simultaneousGesture(MagnifyGesture().onChanged { value in
                let base = pinchStart ?? model.zoom
                pinchStart = base
                model.zoom = min(4, max(1, base * value.magnification))
            }.onEnded { _ in pinchStart = nil })
            .coordinateSpace(name: "cutout")
            .clipped()
        }
    }

    private func displayRect(in size: CGSize) -> CGRect {
        guard let work = model.workImage else { return CGRect(origin: .zero, size: size) }
        let base = min(size.width / CGFloat(work.width), size.height / CGFloat(work.height)) * model.zoom
        let width = CGFloat(work.width) * base, height = CGFloat(work.height) * base
        return CGRect(x: (size.width - width) / 2 + model.offset.width, y: (size.height - height) / 2 + model.offset.height, width: width, height: height)
    }

    @ViewBuilder private func layers(rect: CGRect) -> some View {
        ZStack {
            Checkerboard()
            if let work = model.workImage {
                if model.showOriginal || model.phase == .detecting || model.phase == .choosing || model.phase == .unsupported {
                    image(work)
                } else {
                    if model.tool == .erase || model.tool == .restore { image(work).opacity(0.22) }
                    if let cutout = model.cutout { image(cutout) }
                }
            }
        }
        .frame(width: rect.width, height: rect.height).position(x: rect.midX, y: rect.midY)
    }

    private func image(_ cgImage: CGImage) -> some View {
        Image(decorative: cgImage, scale: 1).resizable().interpolation(.high)
    }

    private func drawGesture(rect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                switch model.tool {
                case .erase, .restore:
                    guard model.phase != .detecting, rect.width > 0 else { return }
                    let point = maskPoint(value.location, in: rect)
                    if lastPoint == nil { model.beginStroke() }
                    model.stroke(from: lastPoint ?? point, to: point, radius: model.brushRadius * model.maskSize.width / rect.width)
                    lastPoint = point
                    cursor = value.location
                case .move:
                    let start = panStart ?? model.offset
                    panStart = start
                    model.offset = CGSize(width: start.width + value.translation.width, height: start.height + value.translation.height)
                case .trim: break
                }
            }
            .onEnded { _ in lastPoint = nil; cursor = nil; panStart = nil }
    }

    private func maskPoint(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: (point.x - rect.minX) / rect.width * model.maskSize.width, y: (point.y - rect.minY) / rect.height * model.maskSize.height)
    }

    // MARK: Trim

    private func trimOverlay(rect: CGRect) -> some View {
        let trim = model.trim
        let frame = CGRect(x: rect.minX + trim.minX * rect.width, y: rect.minY + trim.minY * rect.height,
                           width: trim.width * rect.width, height: trim.height * rect.height)
        return ZStack {
            Path { path in path.addRect(rect); path.addRect(frame) }
                .fill(AppTheme.mediaMask, style: FillStyle(eoFill: true)).allowsHitTesting(false)
            Rectangle().stroke(AppTheme.onMedia, lineWidth: 2).frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY).allowsHitTesting(false)
            handle(at: CGPoint(x: frame.minX, y: frame.midY), edge: .leading, rect: rect)
            handle(at: CGPoint(x: frame.maxX, y: frame.midY), edge: .trailing, rect: rect)
            handle(at: CGPoint(x: frame.midX, y: frame.minY), edge: .top, rect: rect)
            handle(at: CGPoint(x: frame.midX, y: frame.maxY), edge: .bottom, rect: rect)
        }
    }

    private func handle(at point: CGPoint, edge: Edge, rect: CGRect) -> some View {
        Circle().fill(AppTheme.onMedia).overlay(Circle().stroke(AppTheme.ink, lineWidth: 2)).frame(width: 22, height: 22)
            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget).contentShape(Rectangle())
            .position(point)
            .accessibilityLabel("Trim \(edge == .leading ? "left" : edge == .trailing ? "right" : edge == .top ? "top" : "bottom") edge")
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("cutout"))
                .onChanged { value in
                    var trim = model.trim
                    let gap: CGFloat = 0.08
                    let x = min(1, max(0, (value.location.x - rect.minX) / rect.width))
                    let y = min(1, max(0, (value.location.y - rect.minY) / rect.height))
                    switch edge {
                    case .leading: trim = CGRect(x: min(x, trim.maxX - gap), y: trim.minY, width: trim.maxX - min(x, trim.maxX - gap), height: trim.height)
                    case .trailing: trim = CGRect(x: trim.minX, y: trim.minY, width: max(x, trim.minX + gap) - trim.minX, height: trim.height)
                    case .top: trim = CGRect(x: trim.minX, y: min(y, trim.maxY - gap), width: trim.width, height: trim.maxY - min(y, trim.maxY - gap))
                    case .bottom: trim = CGRect(x: trim.minX, y: trim.minY, width: trim.width, height: max(y, trim.minY + gap) - trim.minY)
                    }
                    model.setTrim(trim, recording: !trimRecording)
                    trimRecording = true
                }
                .onEnded { _ in trimRecording = false })
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 12
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(AppTheme.transparencyLight))
            for row in 0..<Int(size.height / cell) + 1 {
                for column in 0..<Int(size.width / cell) + 1 where (row + column).isMultiple(of: 2) {
                    context.fill(Path(CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)), with: .color(AppTheme.transparencyDark))
                }
            }
        }
    }
}
