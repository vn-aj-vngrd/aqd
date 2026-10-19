import ImageIO
import SwiftUI
import UIKit

/// One packaged atlas decode for illustrative UI. Only the explicit Debug
/// sample-population command may copy these crops into labelled sample records.
@MainActor enum WelcomeGarments {
    struct Piece: Decodable, Identifiable {
        let id: String
        let rect: [Double]
        let x: Double, y: Double, w: Double, h: Double, r: Double
    }
    struct Layout: Decodable { let pieces: [Piece]; let formingPositions: [[Double]] }
    static let layout: Layout? = {
        guard let url = Bundle.main.url(forResource: "welcome-atlas", withExtension: "json"),
              let data = try? Data(contentsOf: url), let value = try? JSONDecoder().decode(Layout.self, from: data),
              value.pieces.count == 12, value.formingPositions.count == 12,
              value.pieces.allSatisfy({ $0.rect.count == 4 }), value.formingPositions.allSatisfy({ $0.count == 3 }) else { return nil }
        return value
    }()
    static let images: [String: UIImage] = {
        guard let url = Bundle.main.url(forResource: "welcome-garments", withExtension: "png"), let layout,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let atlas = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { return [:] }
        return Dictionary(uniqueKeysWithValues: layout.pieces.compactMap { piece in
            let rect = CGRect(x: piece.rect[0], y: piece.rect[1], width: piece.rect[2], height: piece.rect[3])
            guard let crop = atlas.cropping(to: rect) else { return nil }
            return (piece.id, UIImage(cgImage: crop))
        })
    }()
}

struct WelcomeWardrobe: View {
    enum Pose { case gathered, forming, settled }
    var pose: Pose = .settled
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 350
            ZStack(alignment: .topLeading) {
                if let layout = WelcomeGarments.layout, WelcomeGarments.images.count == 12 {
                    ForEach(Array(layout.pieces.enumerated()), id: \.element.id) { index, piece in
                        let position = position(piece, forming: layout.formingPositions[index])
                        if let image = WelcomeGarments.images[piece.id] {
                            Image(uiImage: image).resizable().scaledToFit()
                                .overlay {
                                    if ["knit", "dress", "bag", "belt"].contains(piece.id) {
                                        // Welcome-only champagne finish; saved garment media remains untouched.
                                        Image(uiImage: image).renderingMode(.template).resizable().scaledToFit()
                                            .foregroundStyle(AppTheme.accent.opacity(0.12))
                                    }
                                }
                                .frame(width: piece.w * scale, height: piece.h * scale)
                                .rotationEffect(.degrees(position.2))
                                .scaleEffect(pose == .gathered ? 0.9 : 1)
                                .opacity(pose == .gathered ? 0 : 1)
                                .position(x: (position.0 + piece.w / 2) * scale, y: (position.1 + piece.h / 2) * scale)
                                // Each piece arrives a beat after the last, so the closet assembles rather than snaps.
                                .animation(reduceMotion ? nil : .spring(duration: 0.75, bounce: 0.1).delay(Double(index) * 0.035), value: pose)
                        }
                    }
                } else {
                    Image(systemName: "tshirt").font(.system(size: 80)).foregroundStyle(AppTheme.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }.clipped()
        }.aspectRatio(350.0 / 324, contentMode: .fit)
            .frame(maxWidth: typeSize.isAccessibilitySize ? 230 : 350)
            .frame(maxWidth: .infinity).accessibilityHidden(true)
    }
    private func position(_ piece: WelcomeGarments.Piece, forming: [Double]) -> (Double, Double, Double) {
        switch pose {
        case .settled: (piece.x, piece.y, piece.r)
        case .forming: (forming[0], forming[1], forming[2])
        case .gathered: (140 + (piece.x - 140) * 0.2, 130 + (piece.y - 130) * 0.2, piece.r * 0.3)
        }
    }
}

struct IllustrativeLook: View {
    var pieces = ["shirt", "jeans", "sneakers"]
    var body: some View {
        HStack(spacing: 16) {
            ForEach(pieces, id: \.self) { id in
                if let image = WelcomeGarments.images[id] {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }.accessibilityHidden(true)
    }
}

/// Exact reference compositions expressed in a stable 350-point canvas.
struct EntryIllustration: View {
    enum Kind { case introduction, privacy, ready }
    let kind: Kind
    private var height: CGFloat { kind == .introduction ? 156 : kind == .ready ? 190 : 245 }
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 350
            ZStack(alignment: .topLeading) {
                switch kind {
                case .introduction:
                    garment("jeans", x: 27, y: 6, w: 80, h: 145, scale: scale)
                    garment("shirt", x: 105, y: 12, w: 126, h: 123, rotation: -6, scale: scale)
                    garment("sneakers", x: 225, y: 88, w: 79, h: 64, rotation: 10, scale: scale)
                case .ready:
                    garment("knit", x: 20, y: 9, w: 133, h: 145, scale: scale)
                    garment("linen", x: 172, y: 0, w: 100, h: 176, scale: scale)
                    garment("loafers", x: 78, y: 139, w: 91, h: 48, scale: scale)
                case .privacy:
                    garment("shirt", x: 22, y: 12, w: 130, h: 140, scale: scale)
                    garment("sneakers", x: 22, y: 152, w: 120, h: 85, scale: scale)
                    garment("jeans", x: 185, y: 12, w: 115, h: 170, scale: scale)
                    garment("bag", x: 202, y: 170, w: 80, h: 75, scale: scale)
                }
            }
        }.aspectRatio(350 / height, contentMode: .fit).frame(maxWidth: 350).frame(maxWidth: .infinity).accessibilityHidden(true)
    }
    @ViewBuilder private func garment(_ id: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rotation: Double = 0, scale: CGFloat) -> some View {
        if let image = WelcomeGarments.images[id] {
            Image(uiImage: image).resizable().scaledToFit().frame(width: w * scale, height: h * scale)
                .rotationEffect(.degrees(rotation)).position(x: (x + w / 2) * scale, y: (y + h / 2) * scale)
        }
    }
}
