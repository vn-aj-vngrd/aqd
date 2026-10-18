import AQDCore
import SwiftUI

/// What the Agent did for a reply: live steps while it works, then a collapsed "Worked for 12s" line that expands to the same steps.
struct AgentActivityView: View {
    let message: AgentMessage
    let title: String
    let animates: Bool
    @State private var expanded = false

    private var steps: [AgentToolStep] { message.toolSteps ?? [] }

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
    @Environment(AppState.self) private var state
    @State private var previewing: AgentResultItem?

    var body: some View {
        ForEach(steps.filter { !($0.results ?? []).isEmpty }) { step in
            let pieces = (step.results ?? []).filter { $0.kind == .piece }
            let outfits = (step.results ?? []).filter { $0.kind == .outfit && !$0.pieceIDs.isEmpty }
            if !outfits.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    ForEach(outfits) { outfit in Button { previewing = outfit } label: { AgentOutfitCard(item: outfit) }.buttonStyle(.plain) }
                }
            } else if step.tool == "mentioned", pieces.count >= 2 {
                AgentLookPreview(pieces: pieces, others: (step.results ?? []).filter { $0.kind != .piece },
                                 open: { previewing = $0 }, save: saveLook.map { save in { save(pieces.map(\.id)) } })
            } else {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(step.summary).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: AppSpacing.small) {
                        ForEach(step.results ?? []) { item in
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

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Button { open(pieces[0]) } label: { OutfitComposition(pieceIDs: pieces.map(\.id), pieceHeight: 120, limit: 4) }
                .buttonStyle(.plain).accessibilityLabel("Suggested look: " + pieces.map(\.title).joined(separator: ", ")).accessibilityHint("Opens a larger preview")
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggested look").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                Text(pieces.map(\.title).joined(separator: " + ")).font(AppTypography.body).foregroundStyle(AppTheme.ink).fixedSize(horizontal: false, vertical: true)
            }
            if let save {
                Button(action: save) { Label("Save as outfit", systemImage: "plus").compactControl() }.buttonStyle(.plain)
            }
            if !others.isEmpty {
                ScrollView(.horizontal) { LazyHStack(spacing: AppSpacing.small) { ForEach(others) { item in Button { open(item) } label: { AgentResultCard(item: item) }.buttonStyle(.plain) } } }.scrollIndicators(.hidden)
            }
        }.padding(AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
    }
}

/// An outfit drawn like the Closet's: the shared composition of its pieces, then its name and occasion.
struct AgentOutfitCard: View {
    let item: AgentResultItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            OutfitComposition(pieceIDs: item.pieceIDs, pieceHeight: 120, limit: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                if !item.subtitle.isEmpty { Text(item.subtitle).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine).accessibilityHint("Opens a larger preview")
    }
}
