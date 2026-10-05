import SwiftUI
import UIKit

enum AQDColor {
  static let canvas = adaptive(0xF3F3F1, 0x1C1C1E)
  static let surface = adaptive(0xFFFFFF, 0x2C2C2E)
  static let ink = adaptive(0x292C30, 0xF2F2F7)
  static let secondary = adaptive(0x686C72, 0xB8B8BD)
  static let accent = adaptive(0x285A93, 0xB7C9DE)
  static let error = adaptive(0xA1403A, 0xFFB4AB)
  private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(
      uiColor: UIColor { traits in
        let rgb = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((rgb >> 16) & 255) / 255, green: CGFloat((rgb >> 8) & 255) / 255,
          blue: CGFloat(rgb & 255) / 255, alpha: 1)
      })
  }
}

struct EntryPage<Content: View>: View {
  let title: String
  let detail: String
  @ViewBuilder let content: Content
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 12) {
          EntryHeading(title: title)
          Text(detail).font(.body).foregroundStyle(AQDColor.secondary)
        }.padding(.top, 24)
        content
      }.frame(maxWidth: 560, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 40)
        .frame(maxWidth: .infinity)
    }.scrollDismissesKeyboard(.interactively).background(AQDColor.canvas.ignoresSafeArea())
  }
}

struct EntryHeading: View {
  let title: String
  @ScaledMetric(relativeTo: .largeTitle) private var size = 32.0
  var body: some View {
    Text(title).font(.system(size: size)).tracking(-0.8).foregroundStyle(AQDColor.ink)
      .accessibilityAddTraits(.isHeader)
  }
}

struct PrimaryAction: View {
  let title: String
  var busy = false
  var disabled = false
  let action: () -> Void
  private var button: some View {
    Button(action: action) {
      ZStack {
        Text(title).opacity(busy ? 0 : 1)
        if busy { ProgressView().accessibilityLabel("In progress") }
      }.font(.headline).frame(maxWidth: .infinity).frame(minHeight: 28).padding(.vertical, 6)
    }.tint(AQDColor.accent).buttonBorderShape(.capsule).disabled(disabled || busy)
      .accessibilityLabel(
        busy ? title + ", in progress" : title)
  }
  var body: some View {
    if #available(iOS 26.0, *) {
      button.buttonStyle(.glassProminent)
    } else {
      button.buttonStyle(.borderedProminent)
    }
  }
}

struct SecondaryAction: View {
  let title: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title).font(.body).foregroundStyle(AQDColor.ink)
        .frame(maxWidth: .infinity, minHeight: 44).background(AQDColor.canvas).contentShape(.rect)
    }.buttonStyle(.plain)
  }
}

struct InlineNotice: View {
  let text: String?
  var body: some View {
    if let text {
      Text(text).font(.callout).foregroundStyle(AQDColor.error).frame(
        maxWidth: .infinity, alignment: .leading
      )
      .accessibilityIdentifier("entry.error")
    }
  }
}

struct IdentityRow: View {
  let label: String
  let value: String
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label).font(.subheadline).foregroundStyle(AQDColor.secondary)
      Text(value).font(.body).foregroundStyle(AQDColor.ink)
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
  }
}

private struct EntryCompactKey: EnvironmentKey {
  static let defaultValue = false
}
extension EnvironmentValues {
  var entryCompact: Bool {
    get { self[EntryCompactKey.self] }
    set { self[EntryCompactKey.self] = newValue }
  }
}

struct EntryHero: View {
  var firstPiece = false
  @Environment(\.entryCompact) private var compact
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dynamicTypeSize) private var textSize
  @State private var arrived = false
  var body: some View {
    if !textSize.isAccessibilitySize { illustration }
  }
  private var illustration: some View {
    GeometryReader { geometry in
      let scale = min(1, geometry.size.width / 350, geometry.size.height / (firstPiece ? 244 : 324))
      ZStack(alignment: .topLeading) {
        if firstPiece {
          photograph("FirstShirt", width: 204 * scale, height: 232 * scale, padding: 8 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          Image("WelcomeLook").resizable().scaledToFill().frame(
            width: 242 * scale, height: 304 * scale
          ).clipped().clipShape(.rect(cornerRadius: 4))
            .offset(y: 8 * scale)
          photograph("WelcomeShirt", width: 134 * scale, height: 176 * scale, padding: 6)
            .offset(
              x: 216 * scale + (arrived || reduceMotion ? 0 : -12),
              y: arrived || reduceMotion ? 0 : 6
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.32), value: arrived)
          photograph("WelcomeShoe", width: 152 * scale, height: 118 * scale, padding: 6)
            .offset(
              x: 198 * scale + (arrived || reduceMotion ? 0 : -12),
              y: 198 * scale + (arrived || reduceMotion ? 0 : -6)
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.32).delay(0.04), value: arrived)
        }
      }.frame(
        width: firstPiece ? geometry.size.width : 350 * scale,
        height: geometry.size.height, alignment: .topLeading
      )
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }.frame(height: firstPiece ? (compact ? 164 : 244) : (compact ? 220 : 324))
      .clipped()
      .accessibilityHidden(true)
      .onAppear { arrived = true }
  }
  private func photograph(_ name: String, width: CGFloat, height: CGFloat, padding: CGFloat)
    -> some View
  {
    Image(name).resizable().scaledToFill().frame(
      width: width - padding * 2, height: height - padding * 2
    ).clipped()
      .clipShape(.rect(cornerRadius: 4)).padding(padding).background(
        AQDColor.surface, in: .rect(cornerRadius: 8))
  }
}

struct PieceImage: View {
  let piece: Piece
  let store: LocalCloset
  var body: some View {
    if let url = store.photoURL(piece.photoFile), let image = UIImage(contentsOfFile: url.path) {
      Image(uiImage: image).resizable().scaledToFit().accessibilityLabel(piece.name)
    } else {
      Image(systemName: piece.category.symbol).font(.system(size: 56, weight: .light))
        .foregroundStyle(AQDColor.secondary)
        .frame(maxWidth: .infinity, minHeight: 160).accessibilityLabel("\(piece.name), no photo")
    }
  }
}
