import AQDCore
import SwiftUI

struct BackgroundRemovalView: View {
    @Bindable var capture: CaptureModel
    let cropManually: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var input: BackgroundPhotoInput?
    @State private var candidate: PreparedPhoto?
    @State private var processing = false
    @State private var applying = false
    @State private var removedSelected = false
    @State private var error: String?
    @State private var unavailable = false
    @State private var token = UUID()
    @State private var task: Task<Void, Never>?
    @State private var inspect = false
    private var selectedData: Data? { removedSelected ? candidate?.originalData : input?.data }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if processing { OperationProgress(title: "Removing background…") }
                    if let data = selectedData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 360).frame(maxWidth: .infinity)
                            .background(AppTheme.imageGround).accessibilityLabel(removedSelected ? "Removed background preview" : "Original entire photo")
                        Button("Inspect photo") { inspect = true }.frame(minHeight: 44).disabled(processing || candidate == nil)
                    }
                    if candidate != nil {
                        Picker("Compare", selection: $removedSelected) { Text("Original").tag(false); Text("Removed").tag(true) }.pickerStyle(.segmented)
                        Text("Review the edges. People, hangers or other objects may remain. Choose Original or cancel if this result does not work for your piece.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    if let error {
                        SemanticFeedback(role: .warning, message: error)
                        if !unavailable { SecondaryAction(title: "Try again", action: start).disabled(processing || applying) }
                        SecondaryAction(title: "Crop manually") { cancel(); cropManually() }
                    }
                    PrimaryAction(title: "Use photo", isPending: applying) {
                        guard let input, candidate != nil, !processing else { return }
                        applying = true
                        if capture.acceptBackground(removedSelected ? candidate : nil, input: input) { dismiss() }
                        else { error = capture.errorText ?? "The source changed. Cancel and open this task again." }
                        applying = false
                    }.disabled(processing || candidate == nil || applying)
                    SecondaryAction(title: "Cancel") { cancel(); dismiss() }.disabled(applying)
                    Text("Processing stays on this iPhone. Use photo changes only the draft. Original Photos remain unchanged.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Remove background").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button { cancel(); dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Cancel background removal").disabled(applying) } }
                .navigationDestination(isPresented: $inspect) { if let selectedData { BackgroundPhotoInspection(data: selectedData) } }
        }.tint(AppTheme.ink).interactiveDismissDisabled()
            .onAppear { if input == nil { start() } }.onDisappear(perform: cancel)
    }
    private func cancel() { token = UUID(); task?.cancel(); task = nil; processing = false }
    private func start() {
        cancel(); let requestToken = token; processing = true; candidate = nil; removedSelected = false; error = nil
        do {
            let source = try capture.backgroundInput(); input = source
            guard BackgroundRemovalQualification.enabled else {
                unavailable = true; processing = false; error = "Background removal isn’t available in this build. Crop manually or keep your original photo."; return
            }
            unavailable = false
            task = Task {
                do {
                    let proposed = try await PhotoBackgroundRemover.shared.remove(data: source.data)
                    guard !Task.isCancelled, requestToken == token, capture.backgroundSourceIsCurrent(source) else { return }
                    candidate = proposed; processing = false
                } catch {
                    guard !Task.isCancelled, requestToken == token, capture.backgroundSourceIsCurrent(source) else { return }
                    processing = false; self.error = "A usable background preview could not be prepared. Your accepted photo is unchanged. Retry, crop manually or cancel."
                }
            }
        } catch { processing = false; self.error = "Background removal is unavailable for this photo. Your accepted photo and fields are retained. Crop manually or cancel." }
    }
}
private struct BackgroundPhotoInspection: View {
    let data: Data
    @State private var zoom = 1.0
    var body: some View {
        VStack {
            GeometryReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    if let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().frame(width: proxy.size.width * zoom).frame(minHeight: proxy.size.height).background(AppTheme.imageGround) }
                }
            }
            Slider(value: $zoom, in: 1...4).accessibilityLabel("Inspection zoom").accessibilityValue("\(zoom, specifier: "%.1f") times").padding(20)
        }.background(AppTheme.canvas).navigationTitle("Inspect photo").navigationBarTitleDisplayMode(.inline)
    }
}
