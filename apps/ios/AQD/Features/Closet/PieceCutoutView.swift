import SwiftUI

/// Cut a piece out of its photo: automatic subject detection, then Erase, Restore, Trim sides and zoom
/// for a clean transparent result. Done saves a transparent PNG as the draft photo; the original is kept.
struct PieceCutoutView: View {
    @Bindable var capture: CaptureModel
    @Environment(\.dismiss) private var dismiss
    @State private var model: PieceCutoutModel?
    @State private var applying = false
    @State private var error: String?
    @State private var discard = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    editor(model)
                } else {
                    VStack(spacing: AppSpacing.medium) {
                        SemanticFeedback(role: .warning, message: error ?? "Cutout isn’t available for this photo. Your photo and fields are unchanged.")
                        SecondaryAction(title: "Close") { dismiss() }
                    }.padding(AppSpacing.screen).frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .background(AppTheme.canvas)
            .navigationTitle("Cut out piece").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model?.edited == true { discard = true } else { dismiss() }
                    } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Cancel cutout").disabled(applying)
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarSaveAction(title: "Done", isPending: applying) { apply() }
                        .disabled(model == nil || model?.phase == .detecting || model?.hasKeptPixels != true || applying)
                }
            }
        }
        .tint(AppTheme.ink).interactiveDismissDisabled()
        .draftDiscardConfirmation(isPresented: $discard, title: "Discard this cutout?", message: "Your photo stays as it was. Original Photos are unchanged.") { dismiss() }
        .onAppear(perform: open)
        .onDisappear { model?.cancel() }
    }

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
                if capture.acceptBackground(outcome.prepared, input: model.source, crop: outcome.crop) {
                    capture.photoHints = outcome.hints
                    capture.cutoutState = .applied
                    dismiss()
                }
                else { error = capture.errorText ?? "The photo changed. Cancel and open the cutout again." }
            } catch {
                self.error = "The cutout couldn’t be prepared. Your photo is unchanged. Try again."
            }
            applying = false
        }
    }

    private func editor(_ model: PieceCutoutModel) -> some View {
        VStack(spacing: AppSpacing.medium) {
            CutoutCanvas(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.field))
            controls(model)
        }.padding(.horizontal, AppSpacing.screen).padding(.bottom, AppSpacing.small)
    }

    @ViewBuilder private func controls(_ model: PieceCutoutModel) -> some View {
        let bound = Bindable(model)
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if let message = hint(for: model) { SemanticFeedback(role: .warning, message: message) }
            if let error { SemanticFeedback(role: .danger, message: error) }
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.small) {
                    ForEach(PieceCutoutModel.Tool.allCases, id: \.self) { tool in
                        AppChip(title: tool.rawValue, isSelected: model.tool == tool) { model.tool = tool }
                    }
                    AppChip(title: "Original", isSelected: model.showOriginal) { model.showOriginal.toggle() }
                }
            }.scrollIndicators(.hidden)
            if model.tool == .erase || model.tool == .restore {
                sliderRow("Brush", value: bound.brushRadius, range: 8...48)
            }
            sliderRow("Zoom", value: bound.zoom, range: 1...4)
            sliderRow("Softness", value: bound.feather, range: 0...4, onChange: { model.refresh() })
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.small) {
                    Text("Background").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    ForEach(CutoutBackground.allCases, id: \.self) { option in
                        AppChip(title: option.rawValue, isSelected: model.background == option) { model.background = option; model.refresh() }
                    }
                }
            }.scrollIndicators(.hidden)
            HStack(spacing: AppSpacing.medium) {
                iconButton("arrow.uturn.backward", label: "Undo", enabled: model.canUndo) { model.undo() }
                iconButton("arrow.uturn.forward", label: "Redo", enabled: model.canRedo) { model.redo() }
                Button("Reset") { model.reset() }.frame(minHeight: AppControlMetrics.minimumTarget)
                    .disabled(!model.edited && !model.isTrimmed)
                if model.hasSavedCutout {
                    Button("Use original") { capture.useOriginalPhoto(); dismiss() }.frame(minHeight: AppControlMetrics.minimumTarget)
                }
                Spacer()
                Toggle("Fit to piece", isOn: bound.fitToPiece).labelsHidden()
                Text("Fit to piece").font(AppTypography.supporting)
            }
        }
    }

    private func hint(for model: PieceCutoutModel) -> String? {
        switch model.phase {
        case .noSubject: "No piece was detected. Erase the background by hand, or Trim the sides."
        case .failed: "Automatic cutout isn’t available for this photo. Erase the background by hand."
        default: model.phase == .ready && !model.hasKeptPixels ? "Nothing is kept. Use Restore, or Reset." : nil
        }
    }

    private func sliderRow(_ title: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, onChange: (() -> Void)? = nil) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text(title).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).frame(width: 64, alignment: .leading)
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

    var body: some View {
        GeometryReader { proxy in
            let rect = displayRect(in: proxy.size)
            ZStack {
                Color(white: 0.5, opacity: 0.08)
                layers(rect: rect)
                if model.phase == .detecting {
                    ProgressView("Finding the piece…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.group))
                }
                if model.tool == .trim { trimOverlay(rect: rect) }
                if let cursor, model.tool == .erase || model.tool == .restore {
                    Circle().stroke(AppTheme.ink, lineWidth: 1.5).background(Circle().fill(.white.opacity(0.25)))
                        .frame(width: model.brushRadius * 2, height: model.brushRadius * 2).position(cursor).allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(drawGesture(rect: rect), including: model.tool == .trim ? .subviews : .all)
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
                if model.showOriginal || model.phase == .detecting {
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
                .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true)).allowsHitTesting(false)
            Rectangle().stroke(Color.white, lineWidth: 2).frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY).allowsHitTesting(false)
            handle(at: CGPoint(x: frame.minX, y: frame.midY), edge: .leading, rect: rect)
            handle(at: CGPoint(x: frame.maxX, y: frame.midY), edge: .trailing, rect: rect)
            handle(at: CGPoint(x: frame.midX, y: frame.minY), edge: .top, rect: rect)
            handle(at: CGPoint(x: frame.midX, y: frame.maxY), edge: .bottom, rect: rect)
        }
    }

    private func handle(at point: CGPoint, edge: Edge, rect: CGRect) -> some View {
        Circle().fill(Color.white).overlay(Circle().stroke(AppTheme.ink, lineWidth: 2)).frame(width: 22, height: 22)
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
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.97)))
            for row in 0..<Int(size.height / cell) + 1 {
                for column in 0..<Int(size.width / cell) + 1 where (row + column).isMultiple(of: 2) {
                    context.fill(Path(CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)), with: .color(Color(white: 0.88)))
                }
            }
        }
    }
}
