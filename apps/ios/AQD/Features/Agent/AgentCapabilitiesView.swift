import SwiftUI

/// What the Agent can do, each with a prompt that tries it. Lookups answer directly; everything that changes data is a draft the owner reviews.
struct AgentCapability: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let detail: String
    let prompt: String

    static let all: [AgentCapability] = [
        AgentCapability(id: "outfit", symbol: "tshirt", title: "Build outfits", detail: "Suggests or assembles a look from your pieces and names it.", prompt: "Build me an outfit for a date night"),
        AgentCapability(id: "theme", symbol: "square.stack", title: "Make themes", detail: "Groups your outfits into a named theme.", prompt: "Make a theme from my outfits"),
        AgentCapability(id: "label", symbol: "tag", title: "Name and label", detail: "Gives outfits and themes a name, occasion and mood.", prompt: "Name my unnamed outfits"),
        AgentCapability(id: "plan", symbol: "calendar", title: "Plan your days", detail: "Drafts a week in the Planner for you to review.", prompt: "Plan my week"),
        AgentCapability(id: "trip", symbol: "airplane", title: "Plan a trip", detail: "Varied outfits for every day, saved as outfits, a theme and a Planner trip.", prompt: "Plan outfits for my 3 day trip to Boracay"),
        AgentCapability(id: "piece", symbol: "camera", title: "Add a piece", detail: "Attach a photo and review the draft before it joins your closet.", prompt: "Add a new piece from a photo"),
        AgentCapability(id: "find", symbol: "magnifyingglass", title: "Find and count", detail: "Looks up pieces and outfits, and checks what you have worn.", prompt: "What haven’t I worn this month?"),
        AgentCapability(id: "wear", symbol: "checkmark.circle", title: "Log what you wore", detail: "Drafts a wear entry for a day.", prompt: "Log what I wore today"),
        AgentCapability(id: "edit", symbol: "pencil", title: "Edit a piece", detail: "Drafts a change to a piece’s name, color or brand.", prompt: "Change the brand of my "),
        AgentCapability(id: "profile", symbol: "person.crop.circle", title: "Update your profile", detail: "Drafts a new name or caption.", prompt: "Update my profile caption to ")
    ]
}

/// Compact list used on the empty chat and inside the sheet.
struct AgentCapabilityList: View {
    var capabilities = AgentCapability.all
    let enabled: Bool
    let choose: (AgentCapability) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(capabilities) { capability in
                Button { choose(capability) } label: {
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        Image(systemName: capability.symbol).font(.system(size: 17)).foregroundStyle(AppTheme.controlIcon)
                            .frame(width: 28, height: 28).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(capability.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                            Text(capability.detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }.padding(.vertical, AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(!enabled)
                    .accessibilityHint("Sends “\(capability.prompt)”")
                if capability.id != capabilities.last?.id { Divider() }
            }
        }
    }
}

struct AgentCapabilitiesSheet: View {
    let enabled: Bool
    let choose: (AgentCapability) -> Void
    let close: () -> Void

    private let tips: [(symbol: String, text: String)] = [
        ("slash.circle", "Type / or tap the slash button to browse tools."),
        ("plus", "Tap + to attach a photo, take one or add a file."),
        ("hand.raised", "Changes arrive as drafts. You review and apply them; Agent never saves on its own.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        ForEach(tips, id: \.text) { tip in
                            HStack(alignment: .top, spacing: AppSpacing.medium) {
                                Image(systemName: tip.symbol).font(.system(size: 16)).foregroundStyle(AppTheme.controlIcon).frame(width: 24).accessibilityHidden(true)
                                Text(tip.text).font(AppTypography.supporting).foregroundStyle(AppTheme.ink).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text("Try asking").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        AgentCapabilityList(enabled: enabled, choose: choose)
                    }
                }.padding(AppSpacing.screen)
            }.background(AppTheme.canvas).navigationTitle("Help").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(action: close) { Image(systemName: "xmark") }.accessibilityLabel("Close") } }
        }
    }
}

/// Typing "/" in the composer lists every Agent tool; picking one fills the composer so it can be tweaked before sending.
struct AgentSlashMenu: View {
    let query: String
    let choose: (AgentCapability) -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    static func matches(_ query: String) -> [AgentCapability] {
        let text = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty else { return AgentCapability.all }
        return AgentCapability.all.filter { $0.title.lowercased().contains(text) || $0.detail.lowercased().contains(text) || $0.id.contains(text) }
    }

    var body: some View {
        let items = Self.matches(query)
        if !items.isEmpty { panel(items) }
    }

    private func panel(_ items: [AgentCapability]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(items) { item in
                    Button { choose(item) } label: {
                        HStack(spacing: AppSpacing.medium) {
                            Image(systemName: item.symbol).font(.system(size: 16)).foregroundStyle(AppTheme.controlIcon).frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                                Text(item.detail).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }.padding(.horizontal, AppSpacing.large).padding(.vertical, AppSpacing.small + 2)
                            .frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }.scrollIndicators(.hidden).clipShape(RoundedRectangle(cornerRadius: AppRadius.composer))
            .frame(maxHeight: 240).fixedSize(horizontal: false, vertical: true)
            .modifier(AgentPopoverSurface(reduceTransparency: reduceTransparency, contrast: contrast))
            .accessibilityElement(children: .contain).accessibilityLabel("Agent tools")
    }
}

struct AgentPopoverSurface: ViewModifier {
    let reduceTransparency: Bool
    let contrast: ColorSchemeContrast

    @ViewBuilder func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.composer)
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(AppTheme.surface, in: shape).overlay(shape.stroke(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
        }
    }
}

/// The + popover: attach sources and the tools entry, in the same glass panel as the slash menu.
struct AgentAddMenu: View {
    let choose: (Choice) -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    enum Choice { case source(AgentAttachmentSource), tools }

    private var rows: [(symbol: String, title: String, detail: String, choice: Choice)] {
        [("camera", "Camera", "Take a photo", .source(.camera)),
         ("photo", "Photos", "Choose from your library", .source(.photos)),
         ("folder", "Files", "Attach a document", .source(.files)),
         ("wand.and.sparkles", "Tools", "Browse what Agent can do", .tools)]
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows, id: \.title) { row in
                Button { choose(row.choice) } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Image(systemName: row.symbol).font(.system(size: 16)).foregroundStyle(AppTheme.controlIcon).frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                            Text(row.detail).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }.padding(.horizontal, AppSpacing.large).padding(.vertical, AppSpacing.small + 2)
                        .frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.modifier(AgentPopoverSurface(reduceTransparency: reduceTransparency, contrast: contrast))
            .accessibilityElement(children: .contain).accessibilityLabel("Add to message")
    }
}
