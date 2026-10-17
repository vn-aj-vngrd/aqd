import AQDCore
import SwiftUI

struct AgentFeedbackView: View {
    @Environment(AppState.self) private var state
    @State private var library: AgentFeedbackLibrary?
    @State private var error: String?
    var body: some View {
        Group {
            if let library { AgentFeedbackList(library: library) }
            else if error == nil { ProgressView("Loading…") }
            else {
                EmptyStatePage(title: "Feedback couldn’t load", systemImage: "bubble.left",
                               description: Text(error ?? "Your saved feedback is retained."))
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Feedback").navigationBarTitleDisplayMode(.inline).background(AppTheme.canvas)
            .toolbar {
                if library == nil && error != nil {
                    ToolbarItem(placement: .topBarTrailing) { Button("Try again", action: load) }
                }
            }.task { load() }
    }
    private func load() {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            if state.agentModel == nil { state.agentModel = try AgentModel(store: store) }
            guard let agent = state.agentModel else { throw PieceStore.StoreError.corruptStore }
            if state.agentControlsModel == nil { state.agentControlsModel = try AgentControlsModel(store: store) }; library = try AgentFeedbackLibrary(agent: agent, controls: state.agentControlsModel); error = nil
        } catch { self.error = "Your saved feedback is retained. Try again." }
    }
}

private enum FeedbackFilter: String, CaseIterable {
    case all = "All feedback", helpful = "Helpful", notHelpful = "Not helpful", reports = "Reports"
    func includes(_ value: AgentFeedback) -> Bool {
        switch self { case .all: true; case .helpful: value.rating == .helpful; case .notHelpful: value.rating == .notHelpful; case .reports: value.isReport }
    }
}
private struct AgentFeedbackList: View {
    @Environment(AppState.self) private var state
    @Bindable var library: AgentFeedbackLibrary
    @State private var filter: FeedbackFilter = .all
    @State private var editing: AgentFeedback?
    private var visible: [AgentFeedback] { library.items.filter(filter.includes) }
    var body: some View {
        Group {
            if visible.isEmpty && library.error == nil {
                EmptyStatePage(title: LocalizedStringKey(emptyTitle), systemImage: filter == .reports ? "flag" : "bubble.left",
                               description: Text(library.items.isEmpty
                                   ? "Rate an Agent reply, or tap Add feedback to share a problem or idea. Feedback stays on this iPhone until you export it."
                                   : "Nothing matches this filter. Choose All feedback to see your saved feedback."))
            } else { feedbackList }
        }.background(AppTheme.canvas).tint(AppTheme.ink)
            .toolbar {
                if !library.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu { Picker("Show feedback", selection: $filter) { ForEach(FeedbackFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) } } }
                            label: { Image(systemName: "line.3.horizontal.decrease") }.accessibilityLabel("Filter feedback").accessibilityValue(filter.rawValue)
                            .disabled(library.hasPending)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editing = AgentFeedback(isReport: true) } label: { Image(systemName: "plus") }.accessibilityLabel("Add feedback").disabled(library.hasPending)
                }
            }.sheet(item: $editing, onDismiss: { library.reload() }) { value in
                NavigationStack { AgentFeedbackEditor(library: library, feedback: value) }.appAppearance(state.appearance)
            }.onAppear { library.reload() }
    }

    private var emptyTitle: String {
        guard !library.items.isEmpty else { return "No feedback yet" }
        switch filter {
        case .all: return "No feedback yet"
        case .helpful: return "No helpful feedback"
        case .notHelpful: return "No negative feedback"
        case .reports: return "No reports yet"
        }
    }

    private var feedbackList: some View {
        List {
            Section {
                if let error = library.error {
                    SemanticFeedback(role: .danger, message: error)
                    Button(library.hasPending ? "Retry save" : "Reload feedback") { if library.hasPending { _ = library.retry() } else { library.reload() } }
                }
                ForEach(visible) { value in
                    Button { editing = value } label: {
                        HStack(alignment: .top, spacing: AppSpacing.medium) {
                            Image(systemName: value.isReport ? "flag" : value.rating == .helpful ? "hand.thumbsup" : "hand.thumbsdown")
                                .foregroundStyle(AppTheme.controlIcon).frame(width: 24)
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text(value.reasons.first?.title ?? value.title).foregroundStyle(AppTheme.ink)
                                if !value.comment.isEmpty { Text(value.comment).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).lineLimit(2) }
                                Text(value.updatedAt, format: .dateTime.month(.abbreviated).day().hour().minute()).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon)
                        }.frame(minHeight: AppControlMetrics.minimumTarget)
                    }.disabled(library.hasPending || library.agent.active)
                }
            } footer: { Text("Feedback stays on this iPhone until you export it. Deleting a chat also removes its reply feedback.") }
                .listRowBackground(AppTheme.surface)
            if !library.items.isEmpty {
                Section("Common issues") {
                    ForEach(AgentFeedbackReason.allCases.filter { reason in library.items.contains { $0.reasons.contains(reason) } }, id: \.self) { reason in
                        LabeledContent(reason.title, value: String(library.items.filter { $0.reasons.contains(reason) }.count))
                    }
                }.listRowBackground(AppTheme.surface)
            }
        }.listStyle(.insetGrouped).listSectionSpacing(AppSpacing.large).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent)
            .scrollContentBackground(.hidden).background(AppTheme.canvas).tint(AppTheme.ink)
    }
}

struct AgentFeedbackEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var library: AgentFeedbackLibrary
    @State private var draft: AgentFeedback
    private let original: AgentFeedback
    @State private var discard = false
    @State private var deleting = false
    init(library: AgentFeedbackLibrary, feedback: AgentFeedback) { self.library = library; original = library.items.first(where: { $0.id == feedback.id }) ?? feedback; _draft = State(initialValue: feedback) }
    private var saved: Bool { library.items.contains { $0.id == draft.id } }
    private var changed: Bool { !saved || draft != original }
    private var valid: Bool { draft.comment.count <= 1000 && (draft.rating != nil || !draft.reasons.isEmpty || !draft.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
    private var sourceText: (String, String)? {
        if let conversationID = draft.conversationID, let messageID = draft.messageID,
           let chat = library.agent.history.first(where: { $0.id == conversationID }),
           let index = chat.messages.firstIndex(where: { $0.id == messageID && $0.attemptID == draft.attemptID }), index > 0 {
            return (chat.messages[index - 1].source, chat.messages[index].source)
        }
        if let user = original.userText, let response = original.responseText { return (user, response) }
        return nil
    }
    var body: some View {
        Form {
            if let error = library.error { Section { SemanticFeedback(role: .danger, message: error) }.listRowBackground(AppTheme.surface) }
            if draft.messageID != nil {
                Section("Your reaction") {
                    Picker("Rating", selection: $draft.rating) {
                        Text("No rating").tag(AgentFeedbackRating?.none)
                        Text("Helpful").tag(AgentFeedbackRating?.some(.helpful))
                        Text("Not helpful").tag(AgentFeedbackRating?.some(.notHelpful))
                    }.pickerStyle(.segmented)
                    Toggle("Report a problem", isOn: $draft.isReport)
                }.listRowBackground(AppTheme.surface)
            }
            Section(draft.messageID == nil ? "What would you like to share?" : "What could be better?") {
                ForEach(AgentFeedbackReason.allCases.filter { draft.messageID == nil ? [.bug, .idea, .privacy, .other].contains($0) : ![.bug, .idea].contains($0) }, id: \.self) { reason in
                    Button {
                        if draft.reasons.contains(reason) { draft.reasons.removeAll { $0 == reason } } else { draft.reasons.append(reason) }
                        draft.reasons = AgentFeedbackReason.allCases.filter { draft.reasons.contains($0) }
                    } label: {
                        HStack {
                            Text(reason.title).foregroundStyle(AppTheme.ink)
                            Spacer()
                            Image(systemName: draft.reasons.contains(reason) ? "checkmark.circle.fill" : "circle").foregroundStyle(AppTheme.controlIcon)
                        }.frame(minHeight: 44)
                    }.accessibilityValue(draft.reasons.contains(reason) ? "Selected" : "Not selected")
                }
            }.listRowBackground(AppTheme.surface)
            Section {
                TextField("Tell us what happened or what would help…", text: $draft.comment, axis: .vertical).lineLimit(3...8)
                Text("\(draft.comment.count) / 1,000").font(AppTypography.metadata).foregroundStyle(draft.comment.count > 1000 ? AppTheme.error : AppTheme.secondary).frame(maxWidth: .infinity, alignment: .trailing)
            } header: { Text("Details") } footer: { Text("Saved only on this iPhone. Nothing is sent automatically.") }.listRowBackground(AppTheme.surface)
            if draft.messageID != nil {
                Section {
                    Toggle("Include message and reply excerpts", isOn: Binding(get: { draft.includesConversation }, set: { enabled in
                        draft.includesConversation = enabled
                        draft.userText = enabled ? sourceText.map { String($0.0.prefix(1000)) } : nil
                        draft.responseText = enabled ? sourceText.map { String($0.1.prefix(2000)) } : nil
                    })).disabled(sourceText == nil && !draft.includesConversation)
                    if draft.includesConversation {
                        if let user = draft.userText { Text(user).font(AppTypography.supporting).textSelection(.enabled) }
                        if let response = draft.responseText { Text(response).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).textSelection(.enabled) }
                    }
                } footer: { Text("Optional. Review the excerpts before saving or exporting; they may contain private details. Diagnostic counts and version information never include your whole closet or chat.") }.listRowBackground(AppTheme.surface)
            }
            if saved {
                Section {
                    if !changed, let report = exportText {
                        ShareLink(item: report) { AccessoryLabel("Export report", systemImage: "square.and.arrow.up") }
                    }
                    Button(role: .destructive) { deleting = true } label: { AccessoryLabel("Delete feedback", systemImage: "trash", destructive: true) }
                } footer: { Text("Export opens the iPhone share sheet. No server is configured; you choose whether and where to share.") }.listRowBackground(AppTheme.surface)
            }
        }.disabled(library.hasPending).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent)
            .scrollContentBackground(.hidden).background(AppTheme.canvas).tint(AppTheme.ink)
            .navigationTitle(draft.isReport ? "Report a problem" : "Feedback").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { if changed { discard = true } else { dismiss() } } label: { Image(systemName: "xmark") }.accessibilityLabel("Cancel").disabled(library.hasPending)
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarSaveAction(title: library.hasPending ? "Retry save" : "Save") {
                        if library.hasPending { if library.retry() { dismiss() } }
                        else { draft.updatedAt = Date(); if library.save(draft) { dismiss() } }
                    }.disabled(!library.hasPending && (!valid || !changed))
                }
            }.interactiveDismissDisabled(changed || library.hasPending)
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard feedback changes?", message: "Your saved feedback stays unchanged.") { dismiss() }
            .alert("Delete this feedback?", isPresented: $deleting) {
                Button("Cancel", role: .cancel) {}
                Button("Delete feedback", role: .destructive) { if library.save(draft, removing: true) { dismiss() } }
            } message: { Text("Removes this feedback from AQD on this iPhone. Your chat and wardrobe stay.") }
    }
    private var exportText: String? {
        struct Export: Encodable { let appVersion: String; let appBuild: String; let systemVersion: String; let report: AgentFeedbackReport }
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        return (try? encoder.encode(Export(appVersion: version, appBuild: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown", systemVersion: ProcessInfo.processInfo.operatingSystemVersionString, report: draft.report(includingConversation: draft.includesConversation)))).map { String(decoding: $0, as: UTF8.self) }
    }
}
