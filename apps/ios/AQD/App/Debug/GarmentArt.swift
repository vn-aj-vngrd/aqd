#if DEBUG
import CoreGraphics
import Foundation
import ImageIO

/// Flat-lay illustrations of women's clothing, shoes and accessories for the debug seed. Pure CoreGraphics so the same
/// code draws on the phone and in a Mac preview sheet. They are stand-ins for photos, drawn in one consistent style.
enum GarmentArt {
    enum Pattern { case none, stripes, dots, denim, ribbed, floral, gingham }

    /// What the cloth, leather or straw is made of: drives texture and sheen.
    enum Material { case cotton, linen, knit, denim, satin, leather, suede, wool, straw, rubber, metal }

    struct Style {
        var color: CGColor
        var trim: CGColor? = nil
        var pattern: Pattern = .none
        var patternColor: CGColor? = nil
        var material: Material = .cotton
    }

    enum Shape {
        case tee, tank, cami, blouse, crop, cardigan, blazer, jacket
        case dress(Length, sleeves: Bool), skirt(Length, pleated: Bool), pants(Fit), shorts
        case sneakers, flats, heels, sandal, boots
        case tote, crossbody, clutch
        case sunHat, sunglasses, hoops, necklace, scarf, belt, watch
        case bikini, onePiece
    }
    enum Length { case mini, midi, maxi }
    enum Fit { case skinny, straight, wide }

    static func rgb(_ hex: UInt32) -> CGColor {
        CGColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }

    private static let size = CGSize(width: 800, height: 1000)

    // MARK: Entry point

    static func png(_ shape: Shape, _ style: Style) -> Data {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return Data() }
        ctx.translateBy(x: 0, y: size.height); ctx.scaleBy(x: 1, y: -1)
        ctx.setLineJoin(.round); ctx.setLineCap(.round)
        draw(shape, style, in: ctx)
        guard let full = ctx.makeImage() else { return Data() }
        let image = cropped(full) ?? full
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return Data() }
        CGImageDestinationAddImage(destination, image, nil); CGImageDestinationFinalize(destination)
        return data as Data
    }

    /// Trims transparent margins so a small item such as a shoe or earring fills its photo like a real product shot.
    private static func cropped(_ image: CGImage) -> CGImage? {
        guard let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return nil }
        let width = image.width, height = image.height, stride = image.bytesPerRow
        var minX = width, minY = height, maxX = 0, maxY = 0
        for y in 0..<height {
            for x in 0..<width where bytes[y * stride + x * 4 + 3] > 8 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX > minX, maxY > minY else { return nil }
        let pad = Int(Double(max(maxX - minX, maxY - minY)) * 0.12)
        let rect = CGRect(x: max(0, minX - pad), y: max(0, minY - pad), width: min(width, maxX + pad) - max(0, minX - pad), height: min(height, maxY + pad) - max(0, minY - pad))
        return image.cropping(to: rect)
    }

    // MARK: Geometry helpers

    private struct Node { var end: CGPoint; var c1: CGPoint? = nil; var c2: CGPoint? = nil }
    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * size.width, y: y * size.height) }
    private static func mirror(_ p: CGPoint) -> CGPoint { CGPoint(x: size.width - p.x, y: p.y) }
    private static func node(_ x: CGFloat, _ y: CGFloat) -> Node { Node(end: pt(x, y)) }
    private static func curve(_ c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat, _ x: CGFloat, _ y: CGFloat) -> Node {
        Node(end: pt(x, y), c1: pt(c1x, c1y), c2: pt(c2x, c2y))
    }

    /// A symmetric outline from the left half: first node is the top center, last node the bottom center.
    private static func symmetric(_ left: [Node]) -> CGPath {
        let path = CGMutablePath()
        guard let first = left.first else { return path }
        path.move(to: first.end)
        for node in left.dropFirst() {
            if let c1 = node.c1, let c2 = node.c2 { path.addCurve(to: node.end, control1: c1, control2: c2) } else { path.addLine(to: node.end) }
        }
        for index in stride(from: left.count - 1, to: 0, by: -1) {
            let node = left[index], target = mirror(left[index - 1].end)
            if let c1 = node.c1, let c2 = node.c2 { path.addCurve(to: target, control1: mirror(c2), control2: mirror(c1)) } else { path.addLine(to: target) }
        }
        path.closeSubpath()
        return path
    }

    private static func shade(_ color: CGColor, _ amount: CGFloat) -> CGColor {
        let c = color.components ?? [0.5, 0.5, 0.5, 1]
        func clamp(_ v: CGFloat) -> CGFloat { min(1, max(0, v)) }
        return CGColor(red: clamp(c[0] + amount), green: clamp(c.count > 2 ? c[1] + amount : c[0] + amount), blue: clamp(c.count > 2 ? c[2] + amount : c[0] + amount), alpha: 1)
    }

    // MARK: Realism helpers

    /// Deterministic noise in 0...1 so every render of a piece is identical.
    private static func noise(_ x: Int, _ y: Int, _ seed: Int = 0) -> CGFloat {
        var h = UInt64(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263 &+ seed &* 2_147_483_647)
        h = (h ^ (h >> 13)) &* 1_274_126_177
        h ^= h >> 16
        return CGFloat(h & 0xFFFF) / 65_535
    }

    /// Draws something softly blurred by letting a far-away shape cast a blurred shadow back onto the canvas.
    private static func blurred(_ ctx: CGContext, radius: CGFloat, color: CGColor, offset: CGSize = .zero, _ draw: () -> Void) {
        ctx.saveGState()
        let far: CGFloat = 6_000
        ctx.translateBy(x: -far, y: 0)
        ctx.setShadow(offset: CGSize(width: far + offset.width, height: offset.height), blur: radius, color: color)
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.setStrokeColor(CGColor(gray: 0, alpha: 1))
        draw()
        ctx.restoreGState()
    }

    private static func light(_ amount: CGFloat) -> CGColor { CGColor(gray: 1, alpha: amount) }
    private static func shadowTone(_ amount: CGFloat) -> CGColor { CGColor(red: 0.08, green: 0.06, blue: 0.05, alpha: amount) }

    /// Fine cloth or skin texture, drawn inside the current clip.
    private static func texture(_ material: Material, color: CGColor, in ctx: CGContext) {
        let w = Int(size.width), h = Int(size.height)
        switch material {
        case .cotton, .linen, .wool:
            let weave: CGFloat = material == .wool ? 0.05 : 0.035
            ctx.setLineWidth(1)
            ctx.setStrokeColor(shadowTone(weave))
            var y = 0
            while y < h { ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: w, y: y)); y += material == .linen ? 4 : 3 }
            var x = 0
            while x < w { ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: h)); x += material == .linen ? 4 : 3 }
            ctx.strokePath()
            let speckle: CGFloat = material == .linen ? 0.9 : 0.5
            for gy in stride(from: 0, to: h, by: 3) {
                for gx in stride(from: 0, to: w, by: 3) where noise(gx, gy, 1) > (1 - 0.18 * speckle) {
                    ctx.setFillColor(noise(gx, gy, 2) > 0.5 ? shadowTone(0.09) : light(0.10))
                    ctx.fill(CGRect(x: CGFloat(gx), y: CGFloat(gy), width: material == .linen ? 5 : 2, height: material == .linen ? 1.5 : 2))
                }
            }
        case .knit:
            var x: CGFloat = 0
            while x < size.width {
                ctx.setStrokeColor(shadowTone(0.16)); ctx.setLineWidth(5); ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: size.height)); ctx.strokePath()
                ctx.setStrokeColor(light(0.22)); ctx.setLineWidth(3); ctx.move(to: CGPoint(x: x + 6, y: 0)); ctx.addLine(to: CGPoint(x: x + 6, y: size.height)); ctx.strokePath()
                x += 13
            }
            for gy in stride(from: 0, to: h, by: 4) {
                for gx in stride(from: 0, to: w, by: 4) where noise(gx, gy, 3) > 0.8 {
                    ctx.setFillColor(shadowTone(0.08)); ctx.fill(CGRect(x: gx, y: gy, width: 2, height: 3))
                }
            }
        case .denim:
            ctx.setLineWidth(1.4); ctx.setStrokeColor(light(0.10))
            var t: CGFloat = -size.height
            while t < size.width { ctx.move(to: CGPoint(x: t, y: 0)); ctx.addLine(to: CGPoint(x: t + size.height, y: size.height)); t += 5 }
            ctx.strokePath()
            for gy in stride(from: 0, to: h, by: 3) {
                for gx in stride(from: 0, to: w, by: 3) where noise(gx, gy, 4) > 0.84 {
                    ctx.setFillColor(noise(gx, gy, 5) > 0.5 ? light(0.16) : shadowTone(0.14)); ctx.fill(CGRect(x: gx, y: gy, width: 3, height: 2))
                }
            }
        case .satin:
            for gy in stride(from: 0, to: h, by: 4) {
                for gx in stride(from: 0, to: w, by: 4) where noise(gx, gy, 6) > 0.9 {
                    ctx.setFillColor(light(0.05)); ctx.fill(CGRect(x: gx, y: gy, width: 3, height: 3))
                }
            }
        case .leather, .suede:
            let grain: CGFloat = material == .suede ? 0.30 : 0.22
            for gy in stride(from: 0, to: h, by: 2) {
                for gx in stride(from: 0, to: w, by: 2) where noise(gx, gy, 7) > 0.55 {
                    ctx.setFillColor(noise(gx, gy, 8) > 0.5 ? light(grain * 0.35) : shadowTone(grain * 0.5)); ctx.fill(CGRect(x: gx, y: gy, width: 2, height: 2))
                }
            }
        case .straw:
            ctx.setLineWidth(3)
            var y: CGFloat = 0
            while y < size.height {
                ctx.setStrokeColor(shadowTone(0.20)); ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: size.width, y: y)); ctx.strokePath()
                ctx.setStrokeColor(light(0.20)); ctx.move(to: CGPoint(x: 0, y: y + 3)); ctx.addLine(to: CGPoint(x: size.width, y: y + 3)); ctx.strokePath()
                y += 9
            }
            var x: CGFloat = 0
            while x < size.width { ctx.setStrokeColor(shadowTone(0.10)); ctx.setLineWidth(2); ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: size.height)); ctx.strokePath(); x += 11 }
        case .rubber, .metal:
            break
        }
    }

    /// Soft creases and drape shading that follow the garment's long axis, as if photographed lying on a table.
    private static func folds(_ bounds: CGRect, material: Material, in ctx: CGContext) {
        let strength: CGFloat
        switch material { case .satin: strength = 1.3; case .linen: strength = 1.5; case .leather, .suede: strength = 0.55; case .knit, .wool: strength = 0.45; case .straw, .rubber, .metal: strength = 0.0; default: strength = 1 }
        guard strength > 0 else { return }
        let count = Int(max(3, bounds.width / 90))
        for k in 0..<count {
            let seed = k * 17
            let x = bounds.minX + bounds.width * (0.12 + 0.76 * noise(seed, 1, 9))
            let top = bounds.minY + bounds.height * (0.08 + 0.4 * noise(seed, 2, 9))
            let length = bounds.height * (0.25 + 0.5 * noise(seed, 3, 9))
            let bend = (noise(seed, 4, 9) - 0.5) * 70
            let crease = CGMutablePath()
            crease.move(to: CGPoint(x: x, y: top))
            crease.addQuadCurve(to: CGPoint(x: x + bend * 0.6, y: top + length), control: CGPoint(x: x + bend, y: top + length * 0.45))
            blurred(ctx, radius: 18, color: shadowTone(0.10 * strength)) { ctx.addPath(crease); ctx.setLineWidth(22); ctx.strokePath() }
            ctx.saveGState(); ctx.translateBy(x: 13, y: 0)
            blurred(ctx, radius: 16, color: light(0.14 * strength)) { ctx.addPath(crease); ctx.setLineWidth(14); ctx.strokePath() }
            ctx.restoreGState()
        }
        // A couple of broad horizontal sags, like cloth settling across the middle.
        for k in 0..<2 {
            let y = bounds.minY + bounds.height * (0.35 + 0.28 * CGFloat(k)) + (noise(k, 5, 9) - 0.5) * 40
            let sag = CGMutablePath(); sag.move(to: CGPoint(x: bounds.minX + 30, y: y)); sag.addQuadCurve(to: CGPoint(x: bounds.maxX - 30, y: y + 12), control: CGPoint(x: bounds.midX, y: y + 30))
            blurred(ctx, radius: 18, color: shadowTone(0.09 * strength)) { ctx.addPath(sag); ctx.setLineWidth(20); ctx.strokePath() }
        }
    }

    /// Fills a path like a photographed piece: contact shadow, fabric, texture, drape, edge shading, highlight and a fine outline.
    private static func paint(_ path: CGPath, _ style: Style, in ctx: CGContext, outline: Bool = true, shadow: Bool = true) {
        let bounds = path.boundingBoxOfPath
        if shadow {
            blurred(ctx, radius: 26, color: shadowTone(0.30), offset: CGSize(width: 0, height: 20)) { ctx.addPath(path); ctx.fillPath() }
            blurred(ctx, radius: 6, color: shadowTone(0.25), offset: CGSize(width: 0, height: 5)) { ctx.addPath(path); ctx.fillPath() }
        }
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        ctx.setFillColor(style.color); ctx.fill(bounds.insetBy(dx: -4, dy: -4))
        pattern(style, in: ctx)
        texture(style.material, color: style.color, in: ctx)
        folds(bounds, material: style.material, in: ctx)
        // Broad lighting from the upper left.
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [light(0.22), light(0.04), shadowTone(0.04), shadowTone(0.20)] as CFArray, locations: [0, 0.35, 0.65, 1])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: bounds.minX, y: bounds.minY), end: CGPoint(x: bounds.maxX * 0.85, y: bounds.maxY), options: [])
        if style.material == .satin || style.material == .leather || style.material == .metal {
            let sheen = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: [light(0), light(style.material == .satin ? 0.38 : 0.26), light(0)] as CFArray, locations: [0.30, 0.45, 0.60])!
            ctx.drawLinearGradient(sheen, start: CGPoint(x: bounds.minX, y: bounds.minY), end: CGPoint(x: bounds.maxX, y: bounds.minY + bounds.height * 0.55), options: [])
        }
        // Edge darkening where cloth turns away from the light.
        blurred(ctx, radius: 16, color: shadowTone(0.20)) { ctx.addPath(path); ctx.setLineWidth(30); ctx.strokePath() }
        ctx.restoreGState()
        if outline {
            ctx.addPath(path); ctx.setStrokeColor(shade(style.color, -0.30).copy(alpha: 0.75) ?? style.color); ctx.setLineWidth(2); ctx.strokePath()
        }
    }

    private static func pattern(_ style: Style, in ctx: CGContext) {
        let ink = style.patternColor ?? shade(style.color, -0.25)
        ctx.setStrokeColor(ink); ctx.setFillColor(ink)
        switch style.pattern {
        case .none: break
        case .stripes:
            ctx.setLineWidth(14); var y: CGFloat = 0
            while y < size.height { ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: size.width, y: y)); y += 44 }
            ctx.strokePath()
        case .gingham:
            ctx.setAlpha(0.45); ctx.setLineWidth(22)
            var t: CGFloat = 0
            while t < size.width { ctx.move(to: CGPoint(x: t, y: 0)); ctx.addLine(to: CGPoint(x: t, y: size.height)); t += 60 }
            t = 0
            while t < size.height { ctx.move(to: CGPoint(x: 0, y: t)); ctx.addLine(to: CGPoint(x: size.width, y: t)); t += 60 }
            ctx.strokePath(); ctx.setAlpha(1)
        case .dots:
            var y: CGFloat = 20; var row = 0
            while y < size.height { var x: CGFloat = row % 2 == 0 ? 20 : 50
                while x < size.width { ctx.fillEllipse(in: CGRect(x: x, y: y, width: 12, height: 12)); x += 60 }
                y += 44; row += 1 }
        case .floral:
            var y: CGFloat = 20; var row = 0
            while y < size.height { var x: CGFloat = row % 2 == 0 ? 20 : 60
                while x < size.width {
                    for k in 0..<5 {
                        let angle = CGFloat(k) * .pi * 2 / 5
                        ctx.fillEllipse(in: CGRect(x: x + cos(angle) * 9, y: y + sin(angle) * 9, width: 11, height: 11))
                    }
                    x += 84 }
                y += 70; row += 1 }
        case .denim:
            ctx.setAlpha(0.18); ctx.setLineWidth(2)
            var t: CGFloat = -size.height
            while t < size.width { ctx.move(to: CGPoint(x: t, y: 0)); ctx.addLine(to: CGPoint(x: t + size.height, y: size.height)); t += 9 }
            ctx.strokePath(); ctx.setAlpha(1)
        case .ribbed:
            ctx.setAlpha(0.20); ctx.setLineWidth(5)
            var x: CGFloat = 0
            while x < size.width { ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: size.height)); x += 16 }
            ctx.strokePath(); ctx.setAlpha(1)
        }
    }

    private static func line(_ ctx: CGContext, _ a: CGPoint, _ b: CGPoint, _ color: CGColor, _ width: CGFloat = 3, dashed: Bool = false) {
        ctx.saveGState(); ctx.setStrokeColor(color); ctx.setLineWidth(width)
        if dashed { ctx.setLineDash(phase: 0, lengths: [8, 7]) }
        ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath(); ctx.restoreGState()
    }
    private static func button(_ ctx: CGContext, _ x: CGFloat, _ y: CGFloat, _ color: CGColor) {
        let p = pt(x, y)
        ctx.setFillColor(color); ctx.fillEllipse(in: CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14))
    }

    // MARK: Shoes (side views, facing right)

    private static func pathOf(_ build: (CGMutablePath) -> Void) -> CGPath { let p = CGMutablePath(); build(p); p.closeSubpath(); return p }
    private static func cg(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func drawSneaker(_ style: Style, in ctx: CGContext) {
        let dark = shade(style.color, -0.26), sole = style.trim ?? rgb(0xF2EEE6)
        let upper = pathOf { p in
            p.move(to: cg(150, 610)); p.addCurve(to: cg(150, 470), control1: cg(128, 570), control2: cg(130, 500))
            p.addCurve(to: cg(235, 395), control1: cg(160, 430), control2: cg(200, 400))          // heel collar
            p.addCurve(to: cg(330, 350), control1: cg(270, 395), control2: cg(300, 360))          // collar to tongue
            p.addCurve(to: cg(380, 345), control1: cg(345, 330), control2: cg(365, 328))          // tongue top
            p.addCurve(to: cg(560, 470), control1: cg(430, 380), control2: cg(500, 440))          // laces to vamp
            p.addCurve(to: cg(690, 548), control1: cg(620, 480), control2: cg(675, 500))          // toe cap top
            p.addCurve(to: cg(700, 610), control1: cg(706, 570), control2: cg(708, 592))          // toe
        }
        paint(upper, style, in: ctx)
        // Midsole and outsole.
        let midsole = pathOf { p in
            p.move(to: cg(128, 598)); p.addLine(to: cg(704, 598)); p.addCurve(to: cg(690, 662), control1: cg(716, 612), control2: cg(710, 650))
            p.addLine(to: cg(150, 668)); p.addCurve(to: cg(128, 598), control1: cg(126, 656), control2: cg(122, 626))
        }
        paint(midsole, Style(color: sole, material: .rubber), in: ctx)
        ctx.addPath(pathOf { p in p.move(to: cg(140, 668)); p.addLine(to: cg(692, 662)); p.addLine(to: cg(688, 684)); p.addLine(to: cg(146, 690)) })
        ctx.setFillColor(rgb(0xBFA37A)); ctx.fillPath()
        // Toe cap seam, laces, eyelets and heel tab.
        ctx.setStrokeColor(dark.copy(alpha: 0.7)!); ctx.setLineWidth(2.5)
        ctx.addPath(pathOf { p in p.move(to: cg(560, 470)); p.addCurve(to: cg(585, 598), control1: cg(600, 500), control2: cg(600, 560)) }); ctx.strokePath()
        for k in 0..<5 {
            let t = CGFloat(k) / 4
            let a = cg(345 + 170 * t, 352 + 92 * t), b = cg(355 + 170 * t, 395 + 92 * t)
            ctx.setStrokeColor(light(0.85)); ctx.setLineWidth(7); ctx.setLineCap(.round); ctx.move(to: a); ctx.addLine(to: cg(a.x + 42, a.y + 6)); ctx.strokePath()
            ctx.setFillColor(rgb(0xC8C3B8)); ctx.fillEllipse(in: CGRect(x: b.x - 4, y: b.y - 4 - 6, width: 8, height: 8))
        }
        ctx.setStrokeColor(dark.copy(alpha: 0.55)!); ctx.setLineWidth(2)
        ctx.addPath(pathOf { p in p.move(to: cg(150, 470)); p.addCurve(to: cg(168, 590), control1: cg(160, 520), control2: cg(165, 560)) }); ctx.strokePath()
        ctx.setFillColor(shade(style.color, -0.10)); ctx.fill(CGRect(x: 138, y: 420, width: 16, height: 50))
    }

    private static func drawFlat(_ style: Style, in ctx: CGContext) {
        let upper = pathOf { p in
            p.move(to: cg(150, 640)); p.addCurve(to: cg(158, 520), control1: cg(136, 600), control2: cg(140, 556))
            p.addCurve(to: cg(280, 500), control1: cg(185, 500), control2: cg(240, 492))           // heel counter and topline
            p.addCurve(to: cg(400, 540), control1: cg(330, 506), control2: cg(360, 540))           // opening dips
            p.addCurve(to: cg(560, 556), control1: cg(450, 540), control2: cg(500, 548))
            p.addCurve(to: cg(740, 628), control1: cg(640, 566), control2: cg(715, 596))           // pointed toe
            p.addCurve(to: cg(690, 652), control1: cg(750, 640), control2: cg(720, 650))
        }
        paint(upper, style, in: ctx)
        let sole = pathOf { p in p.move(to: cg(146, 640)); p.addLine(to: cg(740, 636)); p.addLine(to: cg(700, 664)); p.addLine(to: cg(158, 668)) }
        paint(sole, Style(color: shade(style.color, -0.34), material: .leather), in: ctx, shadow: false)
        // Opening, bow and edge binding.
        ctx.setStrokeColor(shade(style.color, -0.40).copy(alpha: 0.8)!); ctx.setLineWidth(5)
        ctx.addPath(pathOf { p in p.move(to: cg(165, 528)); p.addCurve(to: cg(430, 548), control1: cg(250, 495), control2: cg(360, 560)) }); ctx.strokePath()
        ctx.setFillColor(shade(style.color, 0.12))
        ctx.addPath(pathOf { p in p.move(to: cg(610, 578)); p.addCurve(to: cg(650, 560), control1: cg(620, 556), control2: cg(640, 552)); p.addCurve(to: cg(650, 596), control1: cg(662, 570), control2: cg(662, 590)); p.addCurve(to: cg(610, 578), control1: cg(636, 604), control2: cg(618, 596)) }); ctx.fillPath()
    }

    private static func drawHeel(_ style: Style, in ctx: CGContext) {
        let upper = pathOf { p in
            p.move(to: cg(190, 440)); p.addCurve(to: cg(330, 470), control1: cg(235, 430), control2: cg(290, 440))    // heel counter topline
            p.addCurve(to: cg(450, 560), control1: cg(380, 500), control2: cg(410, 540))                          // throat
            p.addCurve(to: cg(660, 640), control1: cg(520, 590), control2: cg(600, 610))                          // vamp
            p.addCurve(to: cg(715, 668), control1: cg(690, 646), control2: cg(712, 652))                          // toe
            p.addCurve(to: cg(640, 684), control1: cg(716, 684), control2: cg(668, 690))
            p.addCurve(to: cg(380, 640), control1: cg(560, 676), control2: cg(450, 664))                          // sole to arch
            p.addCurve(to: cg(250, 590), control1: cg(330, 624), control2: cg(280, 610))                          // arch to heel seat
            p.addCurve(to: cg(190, 440), control1: cg(205, 560), control2: cg(180, 500))                          // heel back
        }
        // Slim heel under the seat.
        let heel = pathOf { p in p.move(to: cg(178, 560)); p.addLine(to: cg(262, 590)); p.addLine(to: cg(236, 840)); p.addLine(to: cg(204, 840)) }
        paint(heel, Style(color: shade(style.color, -0.18), material: style.material), in: ctx)
        paint(upper, style, in: ctx)
        ctx.setFillColor(rgb(0x1E1A18)); ctx.fill(CGRect(x: 202, y: 834, width: 36, height: 12))
        // Sole edge highlight and topline binding.
        ctx.setStrokeColor(light(0.35)); ctx.setLineWidth(3)
        ctx.addPath(pathOf { p in p.move(to: cg(200, 444)); p.addCurve(to: cg(325, 474), control1: cg(240, 436), control2: cg(288, 446)) }); ctx.strokePath()
    }

    private static func drawSandal(_ style: Style, in ctx: CGContext) {
        let foot = style.trim ?? shade(style.color, -0.08)
        let bed = pathOf { p in
            p.move(to: cg(150, 640)); p.addCurve(to: cg(190, 610), control1: cg(150, 622), control2: cg(165, 610))
            p.addLine(to: cg(600, 610)); p.addCurve(to: cg(735, 640), control1: cg(680, 610), control2: cg(735, 622))
            p.addCurve(to: cg(690, 668), control1: cg(735, 656), control2: cg(715, 668)); p.addLine(to: cg(190, 672)); p.addCurve(to: cg(150, 640), control1: cg(165, 672), control2: cg(150, 660))
        }
        paint(bed, Style(color: foot, material: style.material), in: ctx)
        ctx.setStrokeColor(shade(foot, -0.2)); ctx.setLineWidth(3); ctx.addPath(bed); ctx.strokePath()
        // Toe strap, instep strap and ankle strap.
        for (x0, x1, lift) in [(560.0, 640.0, 120.0), (410.0, 470.0, 150.0), (270.0, 330.0, 170.0)] {
            let strap = pathOf { p in
                p.move(to: cg(x0, 612)); p.addCurve(to: cg(x1, 612), control1: cg(x0 + 10, 612 - lift), control2: cg(x1 - 10, 612 - lift))
                p.addLine(to: cg(x1 - 14, 612)); p.addCurve(to: cg(x0 + 14, 612), control1: cg(x1 - 22, 612 - lift + 26), control2: cg(x0 + 22, 612 - lift + 26))
            }
            paint(strap, style, in: ctx, shadow: false)
        }
        ctx.setFillColor(rgb(0xD8C27A)); for x in [600.0, 440.0, 300.0] { ctx.fillEllipse(in: CGRect(x: x - 6, y: 618, width: 12, height: 12)) }
    }

    private static func drawBoot(_ style: Style, in ctx: CGContext) {
        let body = pathOf { p in
            p.move(to: cg(250, 200)); p.addLine(to: cg(420, 200)); p.addCurve(to: cg(432, 470), control1: cg(424, 300), control2: cg(430, 400))
            p.addCurve(to: cg(640, 580), control1: cg(480, 500), control2: cg(600, 520))
            p.addCurve(to: cg(690, 640), control1: cg(665, 590), control2: cg(690, 612)); p.addLine(to: cg(690, 700)); p.addLine(to: cg(200, 700))
            p.addCurve(to: cg(250, 200), control1: cg(196, 560), control2: cg(236, 360))
        }
        paint(body, style, in: ctx)
        let heel = pathOf { p in p.move(to: cg(200, 700)); p.addLine(to: cg(330, 700)); p.addLine(to: cg(322, 780)); p.addLine(to: cg(206, 780)) }
        paint(heel, Style(color: shade(style.color, -0.22), material: style.material), in: ctx, shadow: false)
        let sole = pathOf { p in p.move(to: cg(196, 692)); p.addLine(to: cg(694, 692)); p.addLine(to: cg(700, 716)); p.addLine(to: cg(206, 716)) }
        ctx.addPath(sole); ctx.setFillColor(rgb(0x1E1A18)); ctx.fillPath()
        // Elastic gore, pull tab and topline.
        ctx.setFillColor(shade(style.color, -0.12).copy(alpha: 0.55)!); ctx.fill(CGRect(x: 262, y: 360, width: 60, height: 110))
        ctx.setStrokeColor(shade(style.color, 0.18)); ctx.setLineWidth(4); ctx.addPath(pathOf { p in p.move(to: cg(262, 206)); p.addLine(to: cg(414, 206)) }); ctx.strokePath()
        ctx.setFillColor(shade(style.color, -0.12)); ctx.fill(CGRect(x: 330, y: 190, width: 38, height: 46))
    }

    // MARK: Drawing

    private static func draw(_ shape: Shape, _ style: Style, in ctx: CGContext) {
        let dark = shade(style.color, -0.28)
        switch shape {
        case .tee:
            let body = symmetric([node(0.5, 0.2), curve(0.46, 0.2, 0.44, 0.15, 0.40, 0.13), node(0.27, 0.17), node(0.12, 0.30), node(0.20, 0.38), node(0.30, 0.31), curve(0.30, 0.50, 0.29, 0.70, 0.30, 0.88), node(0.5, 0.88)])
            paint(body, style, in: ctx)
        case .tank:
            let body = symmetric([node(0.5, 0.24), curve(0.45, 0.24, 0.42, 0.17, 0.38, 0.10), node(0.33, 0.10), curve(0.34, 0.20, 0.30, 0.26, 0.30, 0.32), curve(0.32, 0.45, 0.29, 0.65, 0.31, 0.88), node(0.5, 0.88)])
            paint(body, style, in: ctx)
        case .cami:
            let body = symmetric([node(0.5, 0.26), curve(0.46, 0.30, 0.42, 0.22, 0.40, 0.10), node(0.385, 0.10), curve(0.385, 0.20, 0.33, 0.26, 0.31, 0.34), curve(0.33, 0.50, 0.30, 0.70, 0.32, 0.86), node(0.5, 0.88)])
            paint(body, style, in: ctx)
            line(ctx, pt(0.34, 0.34), pt(0.66, 0.34), shade(style.color, 0.18), 3)
        case .blouse:
            let body = symmetric([node(0.5, 0.2), curve(0.46, 0.2, 0.44, 0.15, 0.40, 0.13), node(0.27, 0.17), node(0.08, 0.62), node(0.17, 0.66), node(0.31, 0.38), curve(0.30, 0.55, 0.29, 0.72, 0.30, 0.86), node(0.5, 0.88)])
            paint(body, style, in: ctx)
            line(ctx, pt(0.5, 0.2), pt(0.5, 0.88), dark, 3)
            for y in stride(from: 0.28, through: 0.8, by: 0.13) { button(ctx, 0.5, y, shade(style.color, -0.35)) }
        case .crop:
            let body = symmetric([node(0.5, 0.26), curve(0.46, 0.26, 0.44, 0.20, 0.40, 0.18), node(0.27, 0.22), node(0.12, 0.34), node(0.20, 0.42), node(0.30, 0.36), curve(0.30, 0.46, 0.29, 0.54, 0.31, 0.62), node(0.5, 0.62)])
            paint(body, style, in: ctx)
        case .cardigan:
            let body = symmetric([node(0.5, 0.24), curve(0.46, 0.20, 0.44, 0.15, 0.40, 0.13), node(0.27, 0.17), node(0.08, 0.62), node(0.17, 0.66), node(0.31, 0.40), curve(0.30, 0.58, 0.29, 0.74, 0.30, 0.90), node(0.5, 0.90)])
            paint(body, style, in: ctx)
            line(ctx, pt(0.5, 0.24), pt(0.5, 0.90), dark, 4)
            for y in stride(from: 0.32, through: 0.80, by: 0.12) { button(ctx, 0.5, y, shade(style.color, -0.35)) }
        case .blazer:
            let body = symmetric([node(0.5, 0.20), node(0.42, 0.12), node(0.27, 0.15), node(0.09, 0.66), node(0.18, 0.70), node(0.31, 0.38), curve(0.30, 0.58, 0.29, 0.76, 0.30, 0.90), node(0.5, 0.90)])
            paint(body, style, in: ctx)
            let lapel = CGMutablePath(); lapel.move(to: pt(0.42, 0.12)); lapel.addLine(to: pt(0.50, 0.42)); lapel.addLine(to: pt(0.58, 0.12)); lapel.addLine(to: pt(0.5, 0.20)); lapel.closeSubpath()
            paint(lapel, Style(color: shade(style.color, 0.10)), in: ctx, shadow: false)
            line(ctx, pt(0.5, 0.42), pt(0.5, 0.90), dark, 3); button(ctx, 0.5, 0.52, shade(style.color, -0.35)); button(ctx, 0.5, 0.64, shade(style.color, -0.35))
        case .jacket:
            let body = symmetric([node(0.5, 0.18), curve(0.46, 0.18, 0.44, 0.13, 0.40, 0.11), node(0.27, 0.15), node(0.10, 0.62), node(0.19, 0.66), node(0.31, 0.38), curve(0.30, 0.52, 0.29, 0.62, 0.30, 0.74), node(0.5, 0.74)])
            paint(body, style, in: ctx)
            line(ctx, pt(0.5, 0.18), pt(0.5, 0.74), dark, 3)
            line(ctx, pt(0.34, 0.50), pt(0.45, 0.50), dark, 3); line(ctx, pt(0.55, 0.50), pt(0.66, 0.50), dark, 3)
        case .dress(let length, let sleeves):
            let hem: CGFloat = length == .mini ? 0.66 : length == .midi ? 0.80 : 0.93
            let flare: CGFloat = length == .mini ? 0.26 : length == .midi ? 0.22 : 0.20
            var left: [Node] = [node(0.5, 0.2), curve(0.46, 0.2, 0.44, 0.15, 0.41, 0.10)]
            if sleeves { left += [node(0.28, 0.14), node(0.14, 0.28), node(0.22, 0.34), node(0.32, 0.27)] } else { left += [node(0.37, 0.10), curve(0.37, 0.18, 0.33, 0.24, 0.33, 0.30)] }
            left += [curve(0.34, 0.38, 0.38, 0.40, 0.37, 0.45), curve(0.35, 0.52, flare + 0.04, hem - 0.08, flare, hem), node(0.5, hem)]
            paint(symmetric(left), style, in: ctx)
            line(ctx, pt(0.37, 0.45), pt(0.63, 0.45), shade(style.color, -0.18), 3)
        case .skirt(let length, let pleated):
            let hem: CGFloat = length == .mini ? 0.52 : length == .midi ? 0.80 : 0.92
            let body = symmetric([node(0.5, 0.20), node(0.36, 0.20), curve(0.35, 0.28, 0.34, 0.30, 0.33, 0.34), curve(0.28, 0.5, 0.24, hem - 0.1, 0.20, hem), node(0.5, hem)])
            paint(body, style, in: ctx)
            line(ctx, pt(0.36, 0.2), pt(0.64, 0.2), shade(style.color, -0.30), 8)
            if pleated { for k in 1..<6 { let x = 0.5 - 0.30 + CGFloat(k) * 0.10; line(ctx, pt(0.5 + (x - 0.5) * 0.7, 0.34), pt(x, hem), shade(style.color, -0.16), 3) } }
        case .pants(let fit):
            let outer: CGFloat = fit == .wide ? 0.17 : fit == .straight ? 0.23 : 0.28
            let leg: CGFloat = fit == .wide ? 0.43 : fit == .straight ? 0.40 : 0.37
            let body = symmetric([node(0.5, 0.10), node(0.31, 0.10), curve(0.31, 0.2, 0.29, 0.26, 0.28, 0.30), curve(0.25, 0.5, outer, 0.7, outer, 0.92), node(leg - 0.02, 0.92), curve(leg, 0.7, 0.44, 0.52, 0.5, 0.36)])
            paint(body, style, in: ctx)
            line(ctx, pt(0.31, 0.11), pt(0.69, 0.11), shade(style.color, -0.30), 10)
            line(ctx, pt(0.5, 0.11), pt(0.5, 0.36), shade(style.color, -0.22), 3)
            for x in [0.40, 0.60] { button(ctx, x, 0.14, shade(style.color, -0.4)) }
        case .shorts:
            let body = symmetric([node(0.5, 0.20), node(0.31, 0.20), curve(0.31, 0.28, 0.29, 0.32, 0.28, 0.36), curve(0.25, 0.48, 0.22, 0.55, 0.21, 0.62), node(0.45, 0.62), curve(0.45, 0.52, 0.48, 0.46, 0.5, 0.42)])
            paint(body, style, in: ctx)
            line(ctx, pt(0.31, 0.21), pt(0.69, 0.21), shade(style.color, -0.30), 9)
        case .sneakers: drawSneaker(style, in: ctx)
        case .flats: drawFlat(style, in: ctx)
        case .heels: drawHeel(style, in: ctx)
        case .sandal: drawSandal(style, in: ctx)
        case .boots: drawBoot(style, in: ctx)
        case .tote:
            let bag = CGMutablePath(); bag.move(to: CGPoint(x: 210, y: 380)); bag.addLine(to: CGPoint(x: 590, y: 380)); bag.addLine(to: CGPoint(x: 640, y: 800)); bag.addLine(to: CGPoint(x: 160, y: 800)); bag.closeSubpath()
            let handles = CGMutablePath(); handles.move(to: CGPoint(x: 290, y: 380)); handles.addCurve(to: CGPoint(x: 510, y: 380), control1: CGPoint(x: 290, y: 190), control2: CGPoint(x: 510, y: 190))
            ctx.addPath(handles); ctx.setStrokeColor(shade(style.color, -0.22)); ctx.setLineWidth(18); ctx.strokePath()
            paint(bag, style, in: ctx)
        case .crossbody:
            let strap = CGMutablePath(); strap.move(to: CGPoint(x: 250, y: 440)); strap.addCurve(to: CGPoint(x: 550, y: 440), control1: CGPoint(x: 220, y: 100), control2: CGPoint(x: 580, y: 100))
            ctx.addPath(strap); ctx.setStrokeColor(shade(style.color, -0.2)); ctx.setLineWidth(16); ctx.strokePath()
            let bag = CGMutablePath(); bag.addRoundedRect(in: CGRect(x: 170, y: 430, width: 460, height: 320), cornerWidth: 60, cornerHeight: 60)
            paint(bag, style, in: ctx)
            let flap = CGMutablePath(); flap.move(to: CGPoint(x: 172, y: 440)); flap.addLine(to: CGPoint(x: 628, y: 440)); flap.addLine(to: CGPoint(x: 600, y: 560)); flap.addQuadCurve(to: CGPoint(x: 200, y: 560), control: CGPoint(x: 400, y: 640)); flap.closeSubpath()
            paint(flap, Style(color: shade(style.color, 0.06)), in: ctx, shadow: false)
            ctx.setFillColor(style.trim ?? rgb(0xC9A85C)); ctx.fillEllipse(in: CGRect(x: 384, y: 575, width: 32, height: 32))
        case .clutch:
            let bag = CGMutablePath(); bag.addRoundedRect(in: CGRect(x: 120, y: 420, width: 560, height: 300), cornerWidth: 36, cornerHeight: 36)
            paint(bag, style, in: ctx)
            let flap = CGMutablePath(); flap.move(to: CGPoint(x: 122, y: 425)); flap.addLine(to: CGPoint(x: 678, y: 425)); flap.addLine(to: CGPoint(x: 400, y: 560)); flap.closeSubpath()
            paint(flap, Style(color: shade(style.color, 0.08)), in: ctx, shadow: false)
        case .sunHat:
            let brim = CGMutablePath(); brim.addEllipse(in: CGRect(x: 80, y: 480, width: 640, height: 190))
            paint(brim, style, in: ctx)
            let crown = CGMutablePath(); crown.move(to: CGPoint(x: 250, y: 560)); crown.addCurve(to: CGPoint(x: 550, y: 560), control1: CGPoint(x: 250, y: 330), control2: CGPoint(x: 550, y: 330)); crown.addCurve(to: CGPoint(x: 250, y: 560), control1: CGPoint(x: 480, y: 600), control2: CGPoint(x: 320, y: 600))
            paint(crown, style, in: ctx, shadow: false)
            ctx.setFillColor(style.trim ?? rgb(0x2E2A26)); ctx.fill(CGRect(x: 262, y: 500, width: 276, height: 30))
        case .sunglasses:
            for x in [210.0, 450.0] {
                let lens = CGMutablePath(); lens.addRoundedRect(in: CGRect(x: x, y: 430, width: 170, height: 130), cornerWidth: 60, cornerHeight: 60)
                paint(lens, Style(color: style.color), in: ctx)
            }
            line(ctx, CGPoint(x: 380, y: 470), CGPoint(x: 450, y: 470), style.trim ?? shade(style.color, -0.1), 10)
            line(ctx, CGPoint(x: 210, y: 460), CGPoint(x: 140, y: 440), style.trim ?? shade(style.color, -0.1), 10); line(ctx, CGPoint(x: 620, y: 460), CGPoint(x: 690, y: 440), style.trim ?? shade(style.color, -0.1), 10)
        case .hoops:
            for x in [270.0, 530.0] {
                ctx.setStrokeColor(style.color); ctx.setLineWidth(18); ctx.strokeEllipse(in: CGRect(x: x - 90, y: 400, width: 180, height: 180))
            }
        case .necklace:
            let chain = CGMutablePath(); chain.move(to: CGPoint(x: 230, y: 260)); chain.addCurve(to: CGPoint(x: 570, y: 260), control1: CGPoint(x: 260, y: 700), control2: CGPoint(x: 540, y: 700))
            ctx.addPath(chain); ctx.setStrokeColor(style.color); ctx.setLineWidth(8); ctx.strokePath()
            ctx.setFillColor(style.trim ?? style.color); ctx.fillEllipse(in: CGRect(x: 372, y: 540, width: 56, height: 56))
        case .scarf:
            let body = CGMutablePath(); body.move(to: CGPoint(x: 220, y: 200)); body.addLine(to: CGPoint(x: 400, y: 200)); body.addCurve(to: CGPoint(x: 420, y: 800), control1: CGPoint(x: 360, y: 400), control2: CGPoint(x: 460, y: 600)); body.addLine(to: CGPoint(x: 240, y: 800)); body.addCurve(to: CGPoint(x: 220, y: 200), control1: CGPoint(x: 200, y: 600), control2: CGPoint(x: 180, y: 400))
            body.closeSubpath(); paint(body, style, in: ctx)
        case .belt:
            let band = CGMutablePath(); band.addRoundedRect(in: CGRect(x: 80, y: 470, width: 640, height: 50), cornerWidth: 24, cornerHeight: 24)
            paint(band, style, in: ctx)
            ctx.setStrokeColor(style.trim ?? rgb(0xC9A85C)); ctx.setLineWidth(12); ctx.strokeEllipse(in: CGRect(x: 330, y: 460, width: 72, height: 72))
            for k in 0..<5 { ctx.setFillColor(shade(style.color, -0.3)); ctx.fillEllipse(in: CGRect(x: 470 + CGFloat(k) * 40, y: 489, width: 10, height: 10)) }
        case .watch:
            for (y, h) in [(150.0, 300.0), (640.0, 300.0)] { let band = CGMutablePath(); band.addRoundedRect(in: CGRect(x: 340, y: y, width: 120, height: h), cornerWidth: 20, cornerHeight: 20); paint(band, style, in: ctx) }
            let face = CGMutablePath(); face.addEllipse(in: CGRect(x: 270, y: 380, width: 260, height: 260))
            paint(face, Style(color: style.trim ?? rgb(0xC9A85C)), in: ctx)
            ctx.setFillColor(rgb(0xF7F3EA)); ctx.fillEllipse(in: CGRect(x: 300, y: 410, width: 200, height: 200))
            line(ctx, CGPoint(x: 400, y: 510), CGPoint(x: 400, y: 440), rgb(0x2E2A26), 6); line(ctx, CGPoint(x: 400, y: 510), CGPoint(x: 450, y: 530), rgb(0x2E2A26), 6)
        case .bikini:
            for (x, y) in [(300.0, 280.0)] {
                let cup = CGMutablePath(); cup.move(to: CGPoint(x: x, y: y)); cup.addLine(to: CGPoint(x: x + 100, y: y)); cup.addLine(to: CGPoint(x: x + 50, y: y + 150)); cup.closeSubpath()
                paint(cup, style, in: ctx)
                let other = CGMutablePath(); other.move(to: CGPoint(x: x + 110, y: y)); other.addLine(to: CGPoint(x: x + 210, y: y)); other.addLine(to: CGPoint(x: x + 160, y: y + 150)); other.closeSubpath()
                paint(other, style, in: ctx)
                let tie = CGMutablePath(); tie.move(to: CGPoint(x: x + 20, y: y - 5)); tie.addQuadCurve(to: CGPoint(x: x + 190, y: y - 5), control: CGPoint(x: x + 105, y: y - 90))
                ctx.addPath(tie); ctx.setStrokeColor(shade(style.color, -0.15)); ctx.setLineWidth(6); ctx.strokePath()
            }
            let bottom = CGMutablePath(); bottom.move(to: CGPoint(x: 280, y: 560)); bottom.addLine(to: CGPoint(x: 520, y: 560)); bottom.addQuadCurve(to: CGPoint(x: 400, y: 740), control: CGPoint(x: 480, y: 700)); bottom.addQuadCurve(to: CGPoint(x: 280, y: 560), control: CGPoint(x: 320, y: 700)); bottom.closeSubpath()
            paint(bottom, style, in: ctx)
            line(ctx, CGPoint(x: 280, y: 560), CGPoint(x: 220, y: 548), shade(style.color, -0.15), 6); line(ctx, CGPoint(x: 520, y: 560), CGPoint(x: 580, y: 548), shade(style.color, -0.15), 6)
        case .onePiece:
            let body = symmetric([node(0.5, 0.30), curve(0.46, 0.34, 0.42, 0.24, 0.40, 0.12), node(0.385, 0.12), curve(0.385, 0.24, 0.35, 0.32, 0.36, 0.40), curve(0.40, 0.48, 0.38, 0.52, 0.37, 0.56), curve(0.36, 0.64, 0.38, 0.68, 0.40, 0.72), curve(0.44, 0.78, 0.47, 0.76, 0.5, 0.80)])
            paint(body, style, in: ctx)
        }
    }
}
#endif
