import AppKit

// Reproduce the splash's system-font wordmark as an opaque iOS icon.
let output = CommandLine.arguments.dropFirst().first
    ?? "apps/ios/AQD/Resources/LaunchColors.xcassets/AppIcon.appiconset/AppIcon.png"
let size = 1024
guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                              bytesPerRow: size * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("Could not create the wordmark canvas")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
NSColor(srgbRed: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()
let wordmark = NSAttributedString(string: "AQD", attributes: [
    .font: NSFont.systemFont(ofSize: 360, weight: .regular),
    .kern: -9,
    .foregroundColor: NSColor(srgbRed: 41 / 255, green: 44 / 255, blue: 48 / 255, alpha: 1)
])
let textSize = wordmark.size()
wordmark.draw(at: NSPoint(x: (CGFloat(size) - textSize.width) / 2,
                         y: (CGFloat(size) - textSize.height) / 2))
NSGraphicsContext.restoreGraphicsState()
guard let image = context.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the wordmark")
}
try png.write(to: URL(fileURLWithPath: output), options: .atomic)
