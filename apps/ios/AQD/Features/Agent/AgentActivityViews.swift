import AQDCore
import SwiftUI

/// What the Agent did for a reply: live steps while it works, then a collapsed "Worked for 12s" line that expands to the same steps.
struct AgentActivityView: View {
    let message: AgentMessage
    let title: String
    let animates: Bool
    @State private var expanded = false

    private var steps: [AgentToolStep] { (message.toolSteps ?? []).filter { $0.question == nil && $0.rejection == nil } }

    var body: some View {
        if message.isActive { live } else if !steps.isEmpty || (message.elapsedSeconds ?? 0) >= 2 { finished }
    }

    private var live: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                AgentWorkingIndicator(title: "Working for " + AgentActivityFormat.duration(timeline.date.timeIntervalSince(message.createdAt)), animates: animates)
            }
            ForEach(steps) { AgentStepRow(step: $0) }
        }.animation(.easeOut(duration: 0.2), value: steps.count)
    }

    private var finished: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Button { withAnimation(.easeOut(duration: 0.15)) { expanded.toggle() } } label: {
                HStack(spacing: AppSpacing.xSmall) {
                    Text("Worked for " + AgentActivityFormat.duration(message.elapsedSeconds ?? 0)).font(AppTypography.supporting)
                    if !steps.isEmpty { Image(systemName: "chevron.down").font(.caption2.weight(.semibold)).rotationEffect(.degrees(expanded ? 180 : 0)) }
                }.foregroundStyle(AppTheme.secondary).frame(minHeight: 28).contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(steps.isEmpty)
                .accessibilityLabel("Worked for " + AgentActivityFormat.duration(message.elapsedSeconds ?? 0)).accessibilityHint(steps.isEmpty ? "" : expanded ? "Hides the steps" : "Shows the steps")
            if expanded { ForEach(steps) { AgentStepRow(step: $0) } }
        }
    }
}

struct AgentStepRow: View {
    let step: AgentToolStep

    private var symbol: String {
        switch step.tool {
        case "context": "tray.full"
        case "findRecords": "magnifyingglass"
        case "showRecords", "mentioned": "photo.on.rectangle"
        case "wearStats": "chart.bar"
        case "weatherFor": "cloud.sun"
        case "suggestOutfit", "proposeOutfit": "wand.and.sparkles"
        case "proposePlan", "editPlan": "calendar"
        case "proposeTheme", "editTheme": "square.stack"
        case "addPieceFromPhoto": "camera"
        case "recordWear": "checkmark.circle"
        case "proposal": "doc.badge.plus"
        default: "sparkles"
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
            Image(systemName: step.rejection == nil ? symbol : "exclamationmark.circle").font(.caption).foregroundStyle(AppTheme.controlIcon).frame(width: 18)
            Text(step.summary).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).fixedSize(horizontal: false, vertical: true)
        }.accessibilityElement(children: .combine)
    }
}

/// Records the Agent chose to show, as a row of cards under the reply's activity.
struct AgentResultsView: View {
    let steps: [AgentToolStep]
    var saveLook: (([UUID]) -> Void)?
    var iterate: ((String) -> Void)?
    @Environment(AppState.self) private var state
    @State private var previewing: AgentResultItem?

    /// Results whose records were since deleted or replaced (a reseeded closet, a removed piece) are dropped, never drawn as empty boxes.
    private func current(_ step: AgentToolStep) -> [AgentResultItem] {
        (step.results ?? []).filter { item in
            switch item.kind {
            case .piece: state.ownedPieces.contains { $0.id == item.id }
            case .outfit: state.outfits.contains { $0.id == item.id }
            case .theme: state.themes.contains { $0.id == item.id }
            case .plan: true
            }
        }
    }

    var body: some View {
        ForEach(steps.filter { !current($0).isEmpty }) { step in
            let results = current(step)
            let pieces = results.filter { $0.kind == .piece }
            let outfits = results.filter { $0.kind == .outfit && !$0.pieceIDs.isEmpty }
            if !outfits.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    ForEach(outfits) { outfit in Button { previewing = outfit } label: { AgentOutfitCard(item: outfit) }.buttonStyle(.plain) }
                }
            } else if step.tool == "mentioned", pieces.count >= 2 {
                AgentLookPreview(pieces: pieces, others: results.filter { $0.kind != .piece },
                                 open: { previewing = $0 }, save: saveLook.map { save in { save(pieces.map(\.id)) } }, iterate: iterate)
            } else {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(step.summary).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: AppSpacing.small) {
                        ForEach(results) { item in
                            Button { previewing = item } label: { AgentResultCard(item: item) }.buttonStyle(.plain).accessibilityHint("Opens a larger preview")
                        }
                    }
                }.scrollIndicators(.hidden)
            }
            }
        }.sheet(item: $previewing) { AgentPhotoPreview(item: $0).appAppearance(state.appearance).tint(AppTheme.ink) }
    }
}

/// Large view of a piece photo, or every photo of an outfit, opened from a result card.
struct AgentPhotoPreview: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let item: AgentResultItem
    @State private var images: [UIImage] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.medium) {
                    if !item.subtitle.isEmpty { Text(item.subtitle).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity)
                            .background(AppTheme.imageGround).clipShape(RoundedRectangle(cornerRadius: AppRadius.field))
                    }
                    if images.isEmpty { Image(systemName: "photo").font(.largeTitle).foregroundStyle(AppTheme.secondary).padding(.top, AppSpacing.section).accessibilityLabel("No photo") }
                }.padding(AppSpacing.screen)
            }.background(AppTheme.canvas).navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Close") } }
        }.task {
            images = item.photoIDs.compactMap { id in (try? state.store?.photoRendition(id: id, recipe: .fit)).flatMap { UIImage(data: $0) } }
        }
    }
}

struct AgentResultCard: View {
    let item: AgentResultItem

    private var symbol: String {
        switch item.kind { case .piece: "tshirt"; case .outfit: "person.crop.square"; case .theme: "square.stack"; case .plan: "calendar" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            thumbnail.frame(width: 120, height: 132).clipShape(RoundedRectangle(cornerRadius: AppRadius.field))
            Text(item.title).font(AppTypography.supporting).foregroundStyle(AppTheme.ink).lineLimit(1)
            if !item.subtitle.isEmpty { Text(item.subtitle).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).lineLimit(1) }
        }.frame(width: 120, alignment: .leading).accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.title), \(item.subtitle)")
    }

    @ViewBuilder private var thumbnail: some View {
        if item.photoIDs.count == 1, let id = item.photoIDs.first {
            PieceThumbnail(photoID: id)
        } else if item.photoIDs.count > 1 {
            let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(item.photoIDs.prefix(4).enumerated()), id: \.offset) { _, id in PieceThumbnail(photoID: id).frame(height: 65).clipped() }
            }
        } else {
            ZStack { AppTheme.surface; Image(systemName: symbol).font(.title2).foregroundStyle(AppTheme.controlIcon) }
        }
    }
}

/// Pieces the Agent suggested together, shown as one look: the photos side by side, the names beneath, and a way to keep it.
struct AgentLookPreview: View {
    let pieces: [AgentResultItem]
    let others: [AgentResultItem]
    let open: (AgentResultItem) -> Void
    let save: (() -> Void)?
    var iterate: ((String) -> Void)?

    var body: some View {
        AgentWidgetCard(title: "Suggested look", subtitle: pieces.map(\.title).joined(separator: ", ")) {
            Button { open(pieces[0]) } label: { OutfitComposition(pieceIDs: pieces.map(\.id), pieceHeight: 120, limit: 4, ground: .clear) }
                .buttonStyle(.plain).accessibilityLabel("Suggested look: " + pieces.map(\.title).joined(separator: ", ")).accessibilityHint("Opens a larger preview")
            AgentLookActions(save: save, iterate: iterate)
            if !others.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: AppSpacing.small) { ForEach(others) { item in Button { open(item) } label: { AgentResultCard(item: item) }.buttonStyle(.plain) } }
                }.scrollIndicators(.hidden)
            }
        }
    }
}

/// An outfit drawn like the Closet's: the shared composition of its pieces, then its name and occasion.
struct AgentOutfitCard: View {
    let item: AgentResultItem

    var body: some View {
        AgentWidgetCard(title: item.title, subtitle: item.subtitle) {
            OutfitComposition(pieceIDs: item.pieceIDs, pieceHeight: 120, limit: 4, ground: .clear)
        }.accessibilityElement(children: .combine).accessibilityHint("Opens a larger preview")
    }
}

/// A rounded white card in the style of a home-screen widget: the label sits inside, above the content.
struct AgentWidgetCard<Content: View>: View {
    let title: String
    var subtitle = ""
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppTypography.section).foregroundStyle(AppTheme.ink).fixedSize(horizontal: false, vertical: true)
                if !subtitle.isEmpty { Text(subtitle).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            }
            content()
        }.padding(AppSpacing.large).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
    }
}

/// One line of compact actions that never scrolls: full labels when they fit, icons alone when they do not.
struct AdaptiveActions<Content: View>: View {
    @ViewBuilder let content: (_ iconsOnly: Bool) -> Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.small) { content(false) }.fixedSize(horizontal: true, vertical: false)
            HStack(spacing: AppSpacing.small) { content(true) }.fixedSize(horizontal: true, vertical: false)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A compact glass control that keeps only its icon when `iconsOnly` is set.
struct AdaptiveLabel: View {
    let title: String
    let symbol: String
    let iconsOnly: Bool

    var body: some View {
        if iconsOnly { Image(systemName: symbol).compactControl().accessibilityLabel(title) }
        else { Label(title, systemImage: symbol).compactControl() }
    }
}

/// What an owner can do with a suggestion: keep it, ask for another, or steer it. Nothing is saved until they choose to.
struct AgentLookActions: View {
    let save: (() -> Void)?
    let iterate: ((String) -> Void)?
    private let refinements = ["Make it dressier", "Make it more casual", "Swap the shoes", "Add a layer", "Use a different top"]

    var body: some View {
        AdaptiveActions { iconsOnly in
            if let save { Button(action: save) { AdaptiveLabel(title: "Save outfit", symbol: "plus.circle", iconsOnly: iconsOnly) }.buttonStyle(.plain) }
            if let iterate {
                Button { iterate("Show me a different option") } label: { AdaptiveLabel(title: "Try another", symbol: "arrow.triangle.2.circlepath", iconsOnly: iconsOnly) }.buttonStyle(.plain)
                Menu {
                    ForEach(refinements, id: \.self) { text in AccessoryButton(text, systemImage: "slider.horizontal.3") { iterate(text) } }
                } label: { AdaptiveLabel(title: "Adjust", symbol: "slider.horizontal.3", iconsOnly: iconsOnly) }
            }
        }
    }
}

/// A question from the Agent as a choice card, in the style of Claude's and Codex's ask-the-user prompts: a topic chip, the question,
/// numbered answers with an optional detail, a recommended answer, an inline "Something else" field, then Skip and Send.
/// Choosing never sends by itself, so a stray tap can't answer for the owner.
struct AgentQuestionCard: View {
    let question: AgentQuestion
    let send: (String) -> Void
    @State private var chosen: [String] = []
    @State private var note = ""
    @State private var writing = false
    @FocusState private var noteFocused: Bool

    private var multi: Bool { question.multiSelect == true }
    private var answer: String { question.answer(choices: chosen, note: writing ? note : "") }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                if let header = question.header {
                    Text(header).font(AppTypography.metadata.weight(.semibold)).foregroundStyle(AppTheme.secondary)
                        .padding(.horizontal, AppSpacing.small).padding(.vertical, 3)
                        .background(AppTheme.imageGround, in: Capsule())
                }
                Text(question.prompt).font(AppTypography.section).foregroundStyle(AppTheme.ink).fixedSize(horizontal: false, vertical: true)
                if multi { Text("Choose any that apply").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
            }
            VStack(spacing: 0) {
                ForEach(Array(question.options.enumerated()), id: \.element) { index, option in
                    if index > 0 { Divider().overlay(AppTheme.divider).padding(.leading, 52) }
                    optionRow(index: index, option: option)
                }
                Divider().overlay(AppTheme.divider).padding(.leading, 52)
                otherRow
            }
            .background(AppTheme.canvas, in: RoundedRectangle(cornerRadius: AppRadius.group, style: .continuous))
            HStack(spacing: AppSpacing.small) {
                Spacer(minLength: 0)
                Button { send("You choose for me") } label: { Text("Skip").compactControl(tint: AppTheme.secondary) }
                    .buttonStyle(.plain).accessibilityHint("Lets the Agent decide")
                Button { send(answer) } label: {
                    Label("Send", systemImage: "arrow.up").font(.subheadline.weight(.semibold))
                        .foregroundStyle(answer.isEmpty ? AppTheme.secondary : AppTheme.onPrimary).padding(.horizontal, AppSpacing.medium)
                        .frame(minHeight: 32).background(answer.isEmpty ? AppTheme.divider : AppTheme.primaryFill, in: Capsule())
                        .frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(answer.isEmpty).accessibilityLabel("Send answer")
            }
        }
        .padding(AppSpacing.large).frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .sensoryFeedback(.selection, trigger: chosen)
    }

    private func optionRow(index: Int, option: String) -> some View {
        let selected = chosen.contains(option)
        return Button { toggle(option) } label: {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                marker(selected: selected) { Text("\(index + 1)").font(AppTypography.metadata.weight(.semibold)).monospacedDigit() }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.small) {
                        Text(option).font(AppTypography.body.weight(selected ? .semibold : .regular)).foregroundStyle(AppTheme.ink).truncated()
                        if question.recommended == option {
                            Text("Recommended").font(AppTypography.metadata).foregroundStyle(AppTheme.accent)
                        }
                    }
                    if let detail = question.detail(at: index) {
                        Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.medium).padding(.vertical, AppSpacing.small + 2)
            .frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel([option, question.recommended == option ? "recommended" : nil, question.detail(at: index)].compactMap { $0 }.joined(separator: ", "))
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var otherRow: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            marker(selected: writing && !note.isEmpty) { Image(systemName: "pencil").font(.caption.weight(.semibold)) }
            TextField("Something else", text: $note, axis: .vertical).lineLimit(1...3).font(AppTypography.body)
                .focused($noteFocused).submitLabel(.send)
                .onChange(of: noteFocused) { _, focused in if focused { writing = true; if !multi { chosen = [] } } }
                .onSubmit { if !answer.isEmpty { send(answer) } }
                .accessibilityLabel("Type a different answer")
        }
        .padding(.horizontal, AppSpacing.medium).padding(.vertical, AppSpacing.small)
        .frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
        .onTapGesture { noteFocused = true }
    }

    private func marker<Label: View>(selected: Bool, @ViewBuilder label: () -> Label) -> some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: multi ? 6 : 12, style: .continuous)
            shape.fill(selected ? AppTheme.primaryFill : AppTheme.surface)
            shape.stroke(selected ? AppTheme.primaryFill : AppTheme.divider, lineWidth: 1)
            if selected { Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(AppTheme.onPrimary) }
            else { label().foregroundStyle(AppTheme.secondary) }
        }.frame(width: 24, height: 24).accessibilityHidden(true)
    }

    private func toggle(_ option: String) {
        if multi { if let i = chosen.firstIndex(of: option) { chosen.remove(at: i) } else { chosen.append(option) } }
        else { chosen = chosen == [option] ? [] : [option]; writing = false; noteFocused = false }
    }
}

/// A question that was answered: one quiet line with the topic and what the owner chose.
struct AgentAnsweredQuestion: View {
    let question: AgentQuestion
    let answer: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
            Image(systemName: "checkmark.circle").font(.caption).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
            Text(question.header ?? question.prompt).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).lineLimit(1)
            Text(answer).font(AppTypography.supporting.weight(.medium)).foregroundStyle(AppTheme.ink).truncated()
        }.accessibilityElement(children: .combine)
    }
}
