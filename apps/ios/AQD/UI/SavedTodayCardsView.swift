import AQDCore
import SwiftUI

struct SavedTodayCardsView: View {
    @Bindable var model: TodayEditorModel
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [TodayPersonalCard] = []
    @State private var request: TodayCardDeletion?
    @State private var confirming = false
    @State private var pending = false
    @State private var unknown = false
    @State private var error: String?
    @State private var selection: UUID?
    @AccessibilityFocusState private var focused: UUID?
    var body: some View {
        ScrollViewReader { reader in
            List {
                if let error { SemanticFeedback(role: .danger, message: error); Button("Retry reading saved cards", action: reload).frame(minHeight: 44) }
                if let request, !confirming {
                    Section("Retained deletion task") {
                        Text(label(request.card))
                        Text("The previous operation must be checked before another deletion.").foregroundStyle(AppTheme.secondary)
                        Button(unknown ? "Check deletion result" : "Retry deletion") { completeDeletion() }.disabled(pending)
                        if !unknown { Button("Cancel deletion") { cancelDeletion() }.disabled(pending) }
                    }
                }
                if cards.isEmpty && error == nil {
                    Text("No saved notes or photos").font(AppTypography.section).accessibilityAddTraits(.isHeader)
                }
                ForEach(cards) { card in
                    let usage = try? model.state.store?.todayCardUsage(card.id)
                    HStack(spacing: 12) {
                        Button {
                            model.cancelImport()
                            model.nested { instance in instance.kind = card.kind; instance.options = TodayWidgetOptions(personal: card.independentCopy()) }
                            if model.error == nil { dismiss() }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(label(card)).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                                Text(card.kind == .personalNote ? String(card.text.prefix(120)) : "Private photo · \(card.text)").lineLimit(3).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                                Text(usage?.active == true ? "On Today" : usage?.draft == true ? "Used in a retained draft" : usage?.undo == true ? "Retained by layout Undo" : "Saved, not on Today").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                        }.buttonStyle(.plain).disabled(pending || request != nil || model.locked)
                        Menu {
                            Button(card.kind == .personalNote ? "Delete saved note" : "Delete saved photo", role: .destructive) { review(card) }
                        } label: { Label("More for \(label(card))", systemImage: "ellipsis").labelStyle(.iconOnly).frame(width: 44, height: 44) }.disabled(pending || request != nil || model.locked)
                    }.id(card.id).accessibilityFocused($focused, equals: card.id)
                }
            }.navigationTitle("Saved notes and photos").navigationBarTitleDisplayMode(.inline)
                .onAppear { reload(); if let selection { reader.scrollTo(selection); focused = selection } }
                .alert("Delete this saved \(request?.card.kind == .personalPhoto ? "photo" : "note")?", isPresented: $confirming) {
                    Button("Cancel", role: .cancel) { request = nil; focused = selection }
                    Button("Delete", role: .destructive) { completeDeletion() }
                } message: {
                    Text("\(request.map { label($0.card) } ?? "Selected card") will be removed from AQD’s saved cards.\(request?.undo != nil ? " This also releases the layout Undo that retains this card." : "") Original Photos, other cards, wardrobe, journal and exported copies are unaffected. Removing a widget alone does not delete its saved card.")
                }
        }
    }
    private func label(_ card: TodayPersonalCard) -> String { card.title.isEmpty ? card.kind == .personalNote ? "Untitled note" : "Untitled photo" : card.title }
    private func reload() {
        do {
            guard let store = model.state.store else { throw PieceStore.StoreError.corruptStore }
            cards = try store.todayPersonalCards()
            if let retained = try store.pendingTodayCardDeletion() { request = retained; unknown = true }
            error = nil
        } catch { self.error = "Saved cards could not be read. Your previous content is retained; retry." }
    }
    private func review(_ card: TodayPersonalCard) {
        selection = card.id
        do {
            guard let store = model.state.store else { throw PieceStore.StoreError.corruptStore }
            request = try store.reviewTodayCardDeletion(card); confirming = true; error = nil
        } catch {
            self.error = "This card cannot be deleted while it is on Today or used by a retained draft. Remove its placement, then finish or explicitly discard those edits. Check any pending save or deletion first."
        }
    }
    private func completeDeletion() {
        guard !pending, let request else { return }
        pending = true; defer { pending = false }
        do {
            guard let store = model.state.store else { throw PieceStore.StoreError.corruptStore }
            // Read the operation first. An absent acknowledgment permits the same intent only.
            if !(try store.todayCardDeletionApplied(request)) { try store.deleteTodayCard(request) }
            try store.finishTodayCardDeletion(request)
            self.request = nil; unknown = false; error = nil
            reload(); model.state.reloadToday(); model.state.retryPhotoCleanup()
            selection = cards.first?.id; focused = selection
        } catch {
            do {
                guard let store = model.state.store else { throw PieceStore.StoreError.corruptStore }
                if try store.todayCardDeletionApplied(request) {
                    try store.finishTodayCardDeletion(request); self.request = nil; unknown = false
                    reload(); model.state.reloadToday(); model.state.retryPhotoCleanup(); selection = cards.first?.id; focused = selection
                } else { unknown = false; self.error = "Deletion was not completed. The saved card and its media are retained. Retry or cancel." }
            } catch { unknown = true; self.error = "The deletion result is unknown. Check this operation before continuing." }
        }
    }
    private func cancelDeletion() {
        guard !pending, !unknown, let request else { return }
        do {
            guard let store = model.state.store else { throw PieceStore.StoreError.corruptStore }
            if try store.pendingTodayCardDeletion() == request { try store.finishTodayCardDeletion(request, cancelling: true) }
            self.request = nil; error = nil; focused = selection; reload()
        } catch { unknown = true; self.error = "The operation could not be closed. Check its result first." }
    }
}
