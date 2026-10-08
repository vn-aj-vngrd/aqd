import AQDCore
import ImageIO
import SwiftUI

struct PhotoEditorView: View {
    @Bindable var model: CaptureModel
    @Environment(\.dismiss) private var dismiss
    private let sourceID: UUID?
    private let previousRecipe: PhotoEditRecipe
    private let previewImage: UIImage?
    private let previewData: Data?
    private let originalWidth: Int
    private let originalHeight: Int
    @State private var quarterTurns: Int
    @State private var portrait: Bool
    @State private var zoom: Double
    @State private var positionX: Double
    @State private var positionY: Double
    @State private var applying = false
    @State private var discardDecision = false
    @State private var applicationTask: Task<Void, Never>?
    @State private var sliderEditing = false
    @State private var dragOrigin: CGPoint?
    @State private var rotatedPreview: UIImage?
    @State private var previewQuarterTurns = 0
    @State private var previewError: String?
    @State private var previewPreparer = PhotoPreparer()
    @GestureState private var dragging = false

    init(model: CaptureModel) {
        self.model = model
        sourceID = model.draft.photoID
        let recipe = model.draft.photoRecipe
        previousRecipe = recipe
        previewData = model.originalThumbnailData()
        previewImage = previewData.flatMap { UIImage(data: $0) }
        let source = model.originalPhotoData().flatMap { CGImageSourceCreateWithData($0 as CFData, nil) }
        let properties = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
        let width = (properties?[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
        let height = (properties?[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
        originalWidth = width
        originalHeight = height
        _quarterTurns = State(initialValue: recipe.quarterTurns)
        _portrait = State(initialValue: recipe.crop != nil)
        let base = try? PhotoEditRecipe.portrait(originalWidth: width, originalHeight: height, quarterTurns: recipe.quarterTurns)
        _zoom = State(initialValue: recipe.crop.map { min(8, max(1, (base?.crop?.width ?? $0.width) / $0.width)) } ?? 1)
        _positionX = State(initialValue: recipe.crop.map { $0.width < 1 ? min(1, $0.x / (1 - $0.width)) : 0.5 } ?? 0.5)
        _positionY = State(initialValue: recipe.crop.map { $0.height < 1 ? min(1, $0.y / (1 - $0.height)) : 0.5 } ?? 0.5)
    }

    private var recipe: PhotoEditRecipe? {
        if !portrait { return PhotoEditRecipe(quarterTurns: quarterTurns) }
        return try? .portrait(originalWidth: originalWidth, originalHeight: originalHeight,
                              quarterTurns: quarterTurns, zoom: zoom, positionX: positionX, positionY: positionY)
    }

    private var dirty: Bool {
        guard let recipe else { return true }
        guard recipe.quarterTurns == previousRecipe.quarterTurns else { return true }
        switch (recipe.crop, previousRecipe.crop) {
        case (nil, nil): return false
        case let (current?, previous?):
            // Reconstructing normalized framing can introduce subpixel rounding.
            return !zip([current.x, current.y, current.width, current.height],
                        [previous.x, previous.y, previous.width, previous.height])
                .allSatisfy { abs($0 - $1) < 1e-10 }
        default: return true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let previewImage, let recipe, originalWidth > 0, originalHeight > 0 {
                        photoPreview(rotatedPreview ?? previewImage, recipe: recipe).frame(maxWidth: .infinity)
                        if previewQuarterTurns != quarterTurns { HStack { ProgressView(); Text("Preparing preview…") } }
                        Picker("Framing", selection: $portrait) {
                            Text("Fit entire photo").tag(false)
                            Text("Portrait 3:4").tag(true)
                        }.pickerStyle(.segmented)
                        HStack {
                            Button("Rotate", systemImage: "rotate.right") {
                                quarterTurns = (quarterTurns + 1) % 4
                                zoom = 1; positionX = 0.5; positionY = 0.5
                            }.frame(minHeight: 44)
                            Spacer()
                            Button("Reset") { quarterTurns = 0; portrait = false; zoom = 1; positionX = 0.5; positionY = 0.5 }
                                .frame(minHeight: 44)
                        }
                        if portrait {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Zoom").font(.subheadline)
                                Slider(value: $zoom, in: 1...8, onEditingChanged: { sliderEditing = $0 })
                                    .accessibilityLabel("Zoom")
                                    .accessibilityValue(String(format: "%.1f times", zoom))
                                HStack(spacing: 12) {
                                    moveButton("Move crop left", symbol: "arrow.left", x: -0.1, y: 0)
                                    moveButton("Move crop right", symbol: "arrow.right", x: 0.1, y: 0)
                                    moveButton("Move crop up", symbol: "arrow.up", x: 0, y: -0.1)
                                    moveButton("Move crop down", symbol: "arrow.down", x: 0, y: 0.1)
                                }
                            }
                        }
                        Text("Fit keeps the entire photo. Cropping is your choice. Use photo changes only this draft; the original stays available for Reset.")
                            .font(.footnote).foregroundStyle(AppTheme.secondary)
                    } else {
                        ContentUnavailableView("Photo unavailable", systemImage: "photo.badge.exclamationmark",
                                               description: Text("Your fields and saved framing are retained. Return to the draft to replace or recover the photo."))
                    }
                    if let previewError { Text(previewError).font(.subheadline).foregroundStyle(AppTheme.error) }
                    if applying { HStack { ProgressView(); Text("Applying photo edits…") } }
                    if let error = model.errorText { Text(error).font(.subheadline).foregroundStyle(AppTheme.error) }
                }.padding(20).disabled(applying)
            }
            .background(AppTheme.canvas)
            .navigationTitle("Edit photo").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dirty ? (discardDecision = true) : leave() } label: {
                        Label("Back", systemImage: "chevron.left")
                    }.disabled(applying).accessibilityIdentifier("photo.editor.back")
                    .confirmationDialog("Discard photo edits?", isPresented: $discardDecision, titleVisibility: .visible) {
                        Button("Discard edits", role: .destructive) { leave() }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Only this uncommitted framing will be discarded. Your accepted photo, parent draft and original remain unchanged.")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryAction(title: "Use photo", isPending: applying) { apply() }
                    .disabled(applying || recipe == nil || previewImage == nil || previewQuarterTurns != quarterTurns || previewError != nil || originalWidth == 0 || originalHeight == 0)
                    .padding(.horizontal, 20).padding(.vertical, 12).background(AppTheme.canvas)
            }
        }.tint(AppTheme.actionText)
            .interactiveDismissDisabled(dirty || applying)
            .task(id: quarterTurns) { await prepareRotatedPreview() }
            .onDisappear { cancel() }
    }

    private func photoPreview(_ image: UIImage, recipe: PhotoEditRecipe) -> some View {
        return ZStack(alignment: .topLeading) {
            if let crop = recipe.crop {
                Image(uiImage: image).resizable()
                    .frame(width: 240 / crop.width, height: 320 / crop.height)
                    .offset(x: -240 * crop.x / crop.width, y: -320 * crop.y / crop.height)
            } else {
                Image(uiImage: image).resizable().scaledToFit().frame(width: 240, height: 320)
            }
            if portrait && (dragging || sliderEditing) {
                Path { path in
                    for fraction in [1.0 / 3, 2.0 / 3] {
                        path.move(to: CGPoint(x: 240 * fraction, y: 0)); path.addLine(to: CGPoint(x: 240 * fraction, y: 320))
                        path.move(to: CGPoint(x: 0, y: 320 * fraction)); path.addLine(to: CGPoint(x: 240, y: 320 * fraction))
                    }
                }.stroke(.white.opacity(0.8), lineWidth: 1).accessibilityHidden(true)
            }
        }
        .frame(width: 240, height: 320, alignment: .topLeading).background(AppTheme.imageGround)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(portrait ? "Piece photo, portrait crop preview" : "Piece photo, entire image fitted")
        .accessibilityIdentifier("photo.editor.preview")
        .gesture(DragGesture().updating($dragging) { _, state, _ in state = true }.onChanged { value in
            guard portrait, let crop = recipe.crop else { return }
            if dragOrigin == nil { dragOrigin = CGPoint(x: positionX, y: positionY) }
            let origin = dragOrigin ?? .zero
            let travelX = 240 / crop.width - 240
            let travelY = 320 / crop.height - 320
            if travelX > 0 { positionX = min(1, max(0, origin.x - value.translation.width / travelX)) }
            if travelY > 0 { positionY = min(1, max(0, origin.y - value.translation.height / travelY)) }
        }.onEnded { _ in dragOrigin = nil })
    }

    private func moveButton(_ name: String, symbol: String, x: Double, y: Double) -> some View {
        Button { positionX = min(1, max(0, positionX + x)); positionY = min(1, max(0, positionY + y)) } label: {
            Image(systemName: symbol).frame(minWidth: 44, minHeight: 44)
        }.accessibilityLabel(name)
    }

    private func prepareRotatedPreview() async {
        let requestedQuarterTurns = quarterTurns
        previewError = nil
        guard let previewData, let sourceID else { return }
        do {
            // The same pixel renderer owns both preview rotation and the saved rendition.
            // A ≤320px source keeps slider/pan updates cheap; crop geometry stays normalized.
            let prepared = try await previewPreparer.render(data: previewData, sourcePhotoID: sourceID,
                                                           recipe: PhotoEditRecipe(quarterTurns: requestedQuarterTurns))
            guard !Task.isCancelled, requestedQuarterTurns == quarterTurns else { return }
            rotatedPreview = UIImage(data: prepared.renditionData)
            previewQuarterTurns = requestedQuarterTurns
        } catch {
            guard !Task.isCancelled, requestedQuarterTurns == quarterTurns else { return }
            previewError = "The preview couldn’t be prepared. Your accepted photo and framing are unchanged. Reset or try again."
        }
    }

    private func apply() {
        guard let recipe, let sourceID, !applying else { return }
        applying = true
        applicationTask = Task { @MainActor in
            let accepted = await model.applyPhotoEdit(recipe, sourceID: sourceID, previousRecipe: previousRecipe)
            guard !Task.isCancelled else { return }
            applying = false
            if accepted { dismiss() }
        }
    }

    private func leave() {
        cancel()
        dismiss()
    }

    private func cancel() {
        applicationTask?.cancel()
        if applying { model.cancelImport() }
        applying = false
    }
}
