import AQDCore
import SwiftUI

struct PrivateTourView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        if let tour = state.entry.tour {
            if tour.step == 2 {
                TourScreen(scene: 2)
            } else {
                NativeTabs(selection: .constant(tour.step == 3 ? 4 : tour.step),
                           today: { screen(0) }, closet: { screen(1) },
                           planner: { screen(0) }, profile: { screen(3) },
                           agent: { _ in screen(2) }, isReadOnlyPreview: true)
                    .ignoresSafeArea()
            }
        }
    }
    private func screen(_ scene: Int) -> AnyView { AnyView(TourScreen(scene: scene).environment(state)) }
}

/// Only the coach card accepts input. Preview chrome and illustrative records
/// never call the store, model clients or live root actions.
private struct TourScreen: View {
    let scene: Int
    @Environment(AppState.self) private var state
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                TourScene(scene: scene).allowsHitTesting(false).accessibilityHidden(true)
                Color.black.opacity(0.18).ignoresSafeArea(edges: .top).allowsHitTesting(false).accessibilityHidden(true)
                TourCard().padding(.horizontal, 16).padding(.bottom, 20)
                    .frame(maxHeight: geometry.size.height - 20, alignment: .bottom)
            }
        }.background(AppTheme.canvas).interactiveDismissDisabled()
    }
}

private struct TourCard: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    @AccessibilityFocusState private var focusedStep: Int?
    private let titles = ["Today", "Closet", "Agent", "Profile"]
    private let explanations = [
        "See what’s planned and record what you actually wear. Plans and recorded wear stay separate.",
        "Pieces, outfits and themes live in Closet. Planner has its own tab for dates and plans.",
        "Ask about your wardrobe and review drafts before saving. Apple Intelligence assists where available; manual tools remain usable.",
        "Keep fit memories private on this iPhone. Open More to add a fit, edit your profile or find Settings."
    ]
    var body: some View {
        if let tour = state.entry.tour {
            let step = tour.step
            VStack(alignment: .leading, spacing: 16) {
                ViewThatFits(in: .vertical) {
                    explanation(step).fixedSize(horizontal: false, vertical: true)
                    ScrollView { explanation(step) }
                }
                if typeSize.isAccessibilitySize { ActionStack { next(step); back } }
                else { HStack(spacing: 12) { back; next(step) } }
            }.padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
                .onChange(of: step, initial: true) { _, value in focusedStep = value }
                .transaction { $0.disablesAnimations = true }
        }
    }
    private func explanation(_ step: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text("\(step + 1) of 4 · Preview only").font(.subheadline).foregroundStyle(AppTheme.secondary)
                    .accessibilityFocused($focusedStep, equals: step)
                Spacer(minLength: 0)
                Button("Skip tour") { state.updateEntry { $0.skipTour() } }.frame(minHeight: 44)
                    .foregroundStyle(AppTheme.actionText)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(titles[step]).font(AppTypography.section)
                Text(explanations[step]).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var back: some View {
        SecondaryAction(title: "Back") { state.updateEntry { $0.backInTour() } }
            .background(AppTheme.accentSoft, in: Capsule()).accessibilityIdentifier("tour.back")
    }
    private func next(_ step: Int) -> some View {
        PrimaryAction(title: step == 3 ? "Finish tour" : "Next") { state.updateEntry { $0.nextInTour() } }.id(step)
    }
}

private struct TourScene: View {
    let scene: Int
    private let titles = ["Today", "Closet", "Agent", "Profile"]
    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    switch scene {
                    case 0: today
                    case 1: closet
                    case 2: agent
                    default: profile
                    }
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            }.background(AppTheme.canvas)
                .navigationTitle(titles[scene])
                .navigationBarTitleDisplayMode(scene == 2 ? .inline : .large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {} label: { Image(systemName: scene == 0 ? "slider.horizontal.3" : scene == 1 ? "plus" : "ellipsis") }
                    }
                    if scene == 2 {
                        ToolbarItem(placement: .topBarLeading) { Button {} label: { Image(systemName: "chevron.backward") } }
                    }
                }
        }.tint(AppTheme.ink)
    }
    private var today: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Mon 5").font(.subheadline).foregroundStyle(AppTheme.secondary)
            VStack(alignment: .leading, spacing: 12) {
                Text("Today’s look").font(.body.weight(.medium))
                HStack(spacing: 16) {
                    TourArtwork.image("tour-afternoon").frame(width: 96, height: 108).background(AppTheme.imageGround)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("An easy afternoon").font(.body.weight(.medium))
                        Text("Weekend · 4 pieces").font(.subheadline)
                        Text("Planned · Not worn yet").font(.footnote)
                    }
                }
                HStack(spacing: 8) {
                    previewAction("View outfit", primary: false)
                    previewAction("Record wear", primary: true)
                }
            }.padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 12) {
                HStack { Text("Your week in wear"); Spacer(); Text("5–11 Oct").font(.footnote) }
                HStack(spacing: 24) { Text("0 days recorded"); Text("0 pieces worn") }.font(.subheadline)
                HStack { ForEach(Array("MTWTFSS").indices, id: \.self) { index in
                    VStack(spacing: 6) { Circle().fill(AppTheme.divider).frame(width: 26, height: 26); Text(String(Array("MTWTFSS")[index])).font(.footnote) }.frame(maxWidth: .infinity)
                } }
            }.padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    private var closet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("Closet", selection: .constant(0)) {
                Text("Pieces").tag(0); Text("Outfits").tag(1); Text("Themes").tag(2)
            }.pickerStyle(.segmented)
            HStack { Image(systemName: "magnifyingglass"); Text("Search your pieces"); Spacer() }
                .font(.subheadline).foregroundStyle(AppTheme.secondary).padding(12)
                .background(AppTheme.surface, in: Capsule())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 16) {
                piece("shirt", title: "Cotton shirt", detail: "Tops · Blue")
                piece("jeans", title: "Straight jeans", detail: "Bottoms · Indigo")
                piece("sneakers", title: "Ivory sneakers", detail: "Shoes · Ivory")
                piece("bag", title: "Tan crossbody", detail: "Accessories · Tan")
            }
        }
    }
    private var agent: some View {
        VStack(spacing: 24) {
            Text("What would you like\nto wear?").font(.title2).multilineTextAlignment(.center).padding(.vertical, 80)
            ForEach(["Make a look for tonight", "Plan my week", "Rediscover unworn pieces", "Start with a piece"], id: \.self) { title in
                Text(title).font(.subheadline).padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface, in: Capsule())
            }
        }.frame(maxWidth: .infinity)
    }
    private var profile: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text("V").font(.title).foregroundStyle(AppTheme.actionText).frame(width: 64, height: 64).background(AppTheme.accentSoft, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Van").font(.title2.weight(.medium))
                    Text("Everyday · Relaxed · Minimal").font(.subheadline).foregroundStyle(AppTheme.secondary)
                }
            }
            Label("Private on this iPhone", systemImage: "lock").font(.footnote).foregroundStyle(AppTheme.secondary)
            HStack { Text("Your fits").font(AppTypography.section); Text("6").foregroundStyle(AppTheme.secondary) }.frame(minHeight: 44)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 8) {
                fit("tour-fit-blue-coat", date: "6 Oct", fill: true)
                fit("tour-fit-street", date: "5 Oct", fill: true)
                fit("tour-afternoon", date: "4 Oct · Outfit")
                fit("tour-coffee", date: "2 Oct · Outfit")
                fit("tour-evening", date: "28 Sep · Outfit")
                fit("tour-work", date: "26 Sep · Outfit")
            }
        }
    }
    private func previewAction(_ title: String, primary: Bool) -> some View {
        Text(title).font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(primary ? AppTheme.onAccent : AppTheme.actionText)
            .background(primary ? AppTheme.accent : AppTheme.accentSoft, in: Capsule())
    }
    private func piece(_ id: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let image = WelcomeGarments.images[id] {
                Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 134)
                    .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: 4))
            }
            Text(title).font(.body)
            Text(detail).font(.footnote).foregroundStyle(AppTheme.secondary)
        }
    }
    private func fit(_ name: String, date: String, fill: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                TourArtwork.image(name, fill: fill).frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }.aspectRatio(0.75, contentMode: .fit).background(AppTheme.imageGround).clipShape(RoundedRectangle(cornerRadius: 4))
            Text(date).font(.footnote).foregroundStyle(AppTheme.secondary)
        }
    }
}

@MainActor enum TourArtwork {
    static let images: [String: UIImage] = {
        let names = ["tour-fit-blue-coat", "tour-fit-street", "tour-afternoon", "tour-coffee", "tour-evening", "tour-work"]
        return Dictionary(uniqueKeysWithValues: names.compactMap { name in
            let ext = name.hasPrefix("tour-fit") ? "jpg" : "png"
            guard let url = Bundle.main.url(forResource: name, withExtension: ext), let image = UIImage(contentsOfFile: url.path) else { return nil }
            return (name, image)
        })
    }()
    @ViewBuilder static func image(_ name: String, fill: Bool = false) -> some View {
        if let image = images[name] {
            if fill { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(uiImage: image).resizable().scaledToFit() }
        } else { Image(systemName: "tshirt").resizable().scaledToFit().foregroundStyle(AppTheme.secondary) }
    }
}
