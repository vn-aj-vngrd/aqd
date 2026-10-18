#if DEBUG
import CoreGraphics
import Foundation
import ImageIO

/// Flat-lay illustrations of women's clothing, shoes and accessories for the debug seed. Pure CoreGraphics so the same
/// code draws on the phone and in a Mac preview sheet. They are stand-ins for photos, drawn in one consistent style.
enum GarmentArt {
    enum Pattern { case none, stripes, dots, denim, ribbed, floral, gingham }

    struct Style {
        var color: CGColor
        var trim: CGColor? = nil
        var pattern: Pattern = .none
        var patternColor: CGColor? = nil
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
    private static func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * size.width, y: y * size.height) }
    private static func mirror(_ p: CGPoint) -> CGPoint { CGPoint(x: size.width - p.x, y: p.y) }
    private static func N(_ x: CGFloat, _ y: CGFloat) -> Node { Node(end: P(x, y)) }
    private static func C(_ c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat, _ x: CGFloat, _ y: CGFloat) -> Node {
        Node(end: P(x, y), c1: P(c1x, c1y), c2: P(c2x, c2y))
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

    /// Fills a path with the style's color, pattern and a soft top-to-bottom shade, then outlines it.
    private static func paint(_ path: CGPath, _ style: Style, in ctx: CGContext, outline: Bool = true, shadow: Bool = true) {
        if shadow {
            ctx.saveGState(); ctx.translateBy(x: 0, y: 14); ctx.addPath(path); ctx.setFillColor(CGColor(gray: 0, alpha: 0.10)); ctx.fillPath(); ctx.restoreGState()
        }
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        ctx.setFillColor(style.color); ctx.fill(CGRect(origin: .zero, size: size))
        pattern(style, in: ctx)
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [CGColor(gray: 1, alpha: 0.16), CGColor(gray: 1, alpha: 0), CGColor(gray: 0, alpha: 0.14)] as CFArray, locations: [0, 0.45, 1])!
        ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        ctx.restoreGState()
        if outline {
            ctx.addPath(path); ctx.setStrokeColor(shade(style.color, -0.22)); ctx.setLineWidth(3); ctx.strokePath()
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
        let p = P(x, y)
        ctx.setFillColor(color); ctx.fillEllipse(in: CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14))
    }

    // MARK: Drawing

    private static func draw(_ shape: Shape, _ style: Style, in ctx: CGContext) {
        let dark = shade(style.color, -0.28)
        switch shape {
        case .tee:
            let body = symmetric([N(0.5, 0.2), C(0.46, 0.2, 0.44, 0.15, 0.40, 0.13), N(0.27, 0.17), N(0.12, 0.30), N(0.20, 0.38), N(0.30, 0.31), C(0.30, 0.50, 0.29, 0.70, 0.30, 0.88), N(0.5, 0.88)])
            paint(body, style, in: ctx)
        case .tank:
            let body = symmetric([N(0.5, 0.24), C(0.45, 0.24, 0.42, 0.17, 0.38, 0.10), N(0.33, 0.10), C(0.34, 0.20, 0.30, 0.26, 0.30, 0.32), C(0.32, 0.45, 0.29, 0.65, 0.31, 0.88), N(0.5, 0.88)])
            paint(body, style, in: ctx)
        case .cami:
            let body = symmetric([N(0.5, 0.26), C(0.46, 0.30, 0.42, 0.22, 0.40, 0.10), N(0.385, 0.10), C(0.385, 0.20, 0.33, 0.26, 0.31, 0.34), C(0.33, 0.50, 0.30, 0.70, 0.32, 0.86), N(0.5, 0.88)])
            paint(body, style, in: ctx)
            line(ctx, P(0.34, 0.34), P(0.66, 0.34), shade(style.color, 0.18), 3)
        case .blouse:
            let body = symmetric([N(0.5, 0.2), C(0.46, 0.2, 0.44, 0.15, 0.40, 0.13), N(0.27, 0.17), N(0.08, 0.62), N(0.17, 0.66), N(0.31, 0.38), C(0.30, 0.55, 0.29, 0.72, 0.30, 0.86), N(0.5, 0.88)])
            paint(body, style, in: ctx)
            line(ctx, P(0.5, 0.2), P(0.5, 0.88), dark, 3)
            for y in stride(from: 0.28, through: 0.8, by: 0.13) { button(ctx, 0.5, y, shade(style.color, -0.35)) }
        case .crop:
            let body = symmetric([N(0.5, 0.26), C(0.46, 0.26, 0.44, 0.20, 0.40, 0.18), N(0.27, 0.22), N(0.12, 0.34), N(0.20, 0.42), N(0.30, 0.36), C(0.30, 0.46, 0.29, 0.54, 0.31, 0.62), N(0.5, 0.62)])
            paint(body, style, in: ctx)
        case .cardigan:
            let body = symmetric([N(0.5, 0.24), C(0.46, 0.20, 0.44, 0.15, 0.40, 0.13), N(0.27, 0.17), N(0.08, 0.62), N(0.17, 0.66), N(0.31, 0.40), C(0.30, 0.58, 0.29, 0.74, 0.30, 0.90), N(0.5, 0.90)])
            paint(body, style, in: ctx)
            line(ctx, P(0.5, 0.24), P(0.5, 0.90), dark, 4)
            for y in stride(from: 0.32, through: 0.80, by: 0.12) { button(ctx, 0.5, y, shade(style.color, -0.35)) }
        case .blazer:
            let body = symmetric([N(0.5, 0.20), N(0.42, 0.12), N(0.27, 0.15), N(0.09, 0.66), N(0.18, 0.70), N(0.31, 0.38), C(0.30, 0.58, 0.29, 0.76, 0.30, 0.90), N(0.5, 0.90)])
            paint(body, style, in: ctx)
            let lapel = CGMutablePath(); lapel.move(to: P(0.42, 0.12)); lapel.addLine(to: P(0.50, 0.42)); lapel.addLine(to: P(0.58, 0.12)); lapel.addLine(to: P(0.5, 0.20)); lapel.closeSubpath()
            paint(lapel, Style(color: shade(style.color, 0.10)), in: ctx, shadow: false)
            line(ctx, P(0.5, 0.42), P(0.5, 0.90), dark, 3); button(ctx, 0.5, 0.52, shade(style.color, -0.35)); button(ctx, 0.5, 0.64, shade(style.color, -0.35))
        case .jacket:
            let body = symmetric([N(0.5, 0.18), C(0.46, 0.18, 0.44, 0.13, 0.40, 0.11), N(0.27, 0.15), N(0.10, 0.62), N(0.19, 0.66), N(0.31, 0.38), C(0.30, 0.52, 0.29, 0.62, 0.30, 0.74), N(0.5, 0.74)])
            paint(body, style, in: ctx)
            line(ctx, P(0.5, 0.18), P(0.5, 0.74), dark, 3)
            line(ctx, P(0.34, 0.50), P(0.45, 0.50), dark, 3); line(ctx, P(0.55, 0.50), P(0.66, 0.50), dark, 3)
        case .dress(let length, let sleeves):
            let hem: CGFloat = length == .mini ? 0.66 : length == .midi ? 0.80 : 0.93
            let flare: CGFloat = length == .mini ? 0.26 : length == .midi ? 0.22 : 0.20
            var left: [Node] = [N(0.5, 0.2), C(0.46, 0.2, 0.44, 0.15, 0.41, 0.10)]
            if sleeves { left += [N(0.28, 0.14), N(0.14, 0.28), N(0.22, 0.34), N(0.32, 0.27)] } else { left += [N(0.37, 0.10), C(0.37, 0.18, 0.33, 0.24, 0.33, 0.30)] }
            left += [C(0.34, 0.38, 0.38, 0.40, 0.37, 0.45), C(0.35, 0.52, flare + 0.04, hem - 0.08, flare, hem), N(0.5, hem)]
            paint(symmetric(left), style, in: ctx)
            line(ctx, P(0.37, 0.45), P(0.63, 0.45), shade(style.color, -0.18), 3)
        case .skirt(let length, let pleated):
            let hem: CGFloat = length == .mini ? 0.52 : length == .midi ? 0.80 : 0.92
            let body = symmetric([N(0.5, 0.20), N(0.36, 0.20), C(0.35, 0.28, 0.34, 0.30, 0.33, 0.34), C(0.28, 0.5, 0.24, hem - 0.1, 0.20, hem), N(0.5, hem)])
            paint(body, style, in: ctx)
            line(ctx, P(0.36, 0.2), P(0.64, 0.2), shade(style.color, -0.30), 8)
            if pleated { for k in 1..<6 { let x = 0.5 - 0.30 + CGFloat(k) * 0.10; line(ctx, P(0.5 + (x - 0.5) * 0.7, 0.34), P(x, hem), shade(style.color, -0.16), 3) } }
        case .pants(let fit):
            let outer: CGFloat = fit == .wide ? 0.17 : fit == .straight ? 0.23 : 0.28
            let leg: CGFloat = fit == .wide ? 0.43 : fit == .straight ? 0.40 : 0.37
            let body = symmetric([N(0.5, 0.10), N(0.31, 0.10), C(0.31, 0.2, 0.29, 0.26, 0.28, 0.30), C(0.25, 0.5, outer, 0.7, outer, 0.92), N(leg - 0.02, 0.92), C(leg, 0.7, 0.44, 0.52, 0.5, 0.36)])
            paint(body, style, in: ctx)
            line(ctx, P(0.31, 0.11), P(0.69, 0.11), shade(style.color, -0.30), 10)
            line(ctx, P(0.5, 0.11), P(0.5, 0.36), shade(style.color, -0.22), 3)
            for x in [0.40, 0.60] { button(ctx, x, 0.14, shade(style.color, -0.4)) }
        case .shorts:
            let body = symmetric([N(0.5, 0.20), N(0.31, 0.20), C(0.31, 0.28, 0.29, 0.32, 0.28, 0.36), C(0.25, 0.48, 0.22, 0.55, 0.21, 0.62), N(0.45, 0.62), C(0.45, 0.52, 0.48, 0.46, 0.5, 0.42)])
            paint(body, style, in: ctx)
            line(ctx, P(0.31, 0.21), P(0.69, 0.21), shade(style.color, -0.30), 9)
        case .sneakers:
            let sole = CGMutablePath(); sole.addRoundedRect(in: CGRect(x: 120, y: 620, width: 560, height: 70), cornerWidth: 34, cornerHeight: 34)
            let upper = CGMutablePath(); upper.move(to: CGPoint(x: 140, y: 620)); upper.addCurve(to: CGPoint(x: 230, y: 380), control1: CGPoint(x: 120, y: 520), control2: CGPoint(x: 170, y: 400))
            upper.addCurve(to: CGPoint(x: 360, y: 420), control1: CGPoint(x: 280, y: 360), control2: CGPoint(x: 330, y: 420))
            upper.addCurve(to: CGPoint(x: 600, y: 520), control1: CGPoint(x: 460, y: 430), control2: CGPoint(x: 560, y: 470)); upper.addCurve(to: CGPoint(x: 680, y: 620), control1: CGPoint(x: 660, y: 540), control2: CGPoint(x: 690, y: 580))
            upper.closeSubpath()
            paint(upper, style, in: ctx); paint(sole, Style(color: style.trim ?? rgb(0xF2EFEA)), in: ctx)
            for k in 0..<4 { line(ctx, CGPoint(x: 330 + CGFloat(k) * 40, y: 425 + CGFloat(k) * 14), CGPoint(x: 350 + CGFloat(k) * 40, y: 470 + CGFloat(k) * 12), dark, 4) }
        case .flats:
            let upper = CGMutablePath(); upper.move(to: CGPoint(x: 130, y: 600)); upper.addCurve(to: CGPoint(x: 250, y: 470), control1: CGPoint(x: 130, y: 520), control2: CGPoint(x: 190, y: 480))
            upper.addCurve(to: CGPoint(x: 520, y: 500), control1: CGPoint(x: 330, y: 450), control2: CGPoint(x: 430, y: 470)); upper.addCurve(to: CGPoint(x: 680, y: 600), control1: CGPoint(x: 620, y: 520), control2: CGPoint(x: 690, y: 560)); upper.closeSubpath()
            paint(upper, style, in: ctx)
            let sole = CGMutablePath(); sole.addRoundedRect(in: CGRect(x: 130, y: 600, width: 550, height: 28), cornerWidth: 14, cornerHeight: 14); paint(sole, Style(color: shade(style.color, -0.22)), in: ctx)
        case .heels:
            let upper = CGMutablePath(); upper.move(to: CGPoint(x: 140, y: 400)); upper.addCurve(to: CGPoint(x: 330, y: 520), control1: CGPoint(x: 150, y: 470), control2: CGPoint(x: 250, y: 520))
            upper.addCurve(to: CGPoint(x: 690, y: 640), control1: CGPoint(x: 450, y: 520), control2: CGPoint(x: 640, y: 560)); upper.addLine(to: CGPoint(x: 700, y: 665))
            upper.addCurve(to: CGPoint(x: 330, y: 575), control1: CGPoint(x: 560, y: 650), control2: CGPoint(x: 430, y: 590)); upper.addLine(to: CGPoint(x: 150, y: 480)); upper.closeSubpath()
            paint(upper, style, in: ctx)
            let heel = CGMutablePath(); heel.move(to: CGPoint(x: 140, y: 400)); heel.addLine(to: CGPoint(x: 190, y: 420)); heel.addLine(to: CGPoint(x: 205, y: 740)); heel.addLine(to: CGPoint(x: 168, y: 740)); heel.closeSubpath()
            paint(heel, Style(color: shade(style.color, -0.12)), in: ctx)
        case .sandal:
            let sole = CGMutablePath(); sole.addRoundedRect(in: CGRect(x: 130, y: 600, width: 560, height: 40), cornerWidth: 20, cornerHeight: 20); paint(sole, Style(color: style.trim ?? shade(style.color, -0.1)), in: ctx)
            for x in [300.0, 420.0, 540.0] {
                let strap = CGMutablePath(); strap.move(to: CGPoint(x: x, y: 600)); strap.addQuadCurve(to: CGPoint(x: x + 70, y: 600), control: CGPoint(x: x + 35, y: 470)); strap.addLine(to: CGPoint(x: x + 50, y: 600)); strap.addQuadCurve(to: CGPoint(x: x + 20, y: 600), control: CGPoint(x: x + 35, y: 510)); strap.closeSubpath()
                paint(strap, style, in: ctx, shadow: false)
            }
        case .boots:
            let boot = CGMutablePath(); boot.move(to: CGPoint(x: 250, y: 200)); boot.addLine(to: CGPoint(x: 420, y: 200)); boot.addLine(to: CGPoint(x: 430, y: 470))
            boot.addCurve(to: CGPoint(x: 660, y: 560), control1: CGPoint(x: 480, y: 500), control2: CGPoint(x: 620, y: 520)); boot.addLine(to: CGPoint(x: 670, y: 640)); boot.addLine(to: CGPoint(x: 230, y: 640)); boot.closeSubpath()
            paint(boot, style, in: ctx)
            let sole = CGMutablePath(); sole.addRect(CGRect(x: 225, y: 640, width: 450, height: 40)); paint(sole, Style(color: shade(style.color, -0.3)), in: ctx)
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
            let body = symmetric([N(0.5, 0.30), C(0.46, 0.34, 0.42, 0.24, 0.40, 0.12), N(0.385, 0.12), C(0.385, 0.24, 0.35, 0.32, 0.36, 0.40), C(0.40, 0.48, 0.38, 0.52, 0.37, 0.56), C(0.36, 0.64, 0.38, 0.68, 0.40, 0.72), C(0.44, 0.78, 0.47, 0.76, 0.5, 0.80)])
            paint(body, style, in: ctx)
        }
    }
}
#endif
