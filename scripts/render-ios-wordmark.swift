import AppKit

// Render the AQD system-letter mark with a restrained gold Q.
// Keep the canvas opaque and square; iOS supplies the Home Screen mask.
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
NSColor.white.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()
let wordmark = NSMutableAttributedString(string: "AQD", attributes: [
    .font: NSFont.systemFont(ofSize: 330, weight: .regular),
    .kern: 4,
    .foregroundColor: NSColor(srgbRed: 36 / 255, green: 35 / 255, blue: 33 / 255, alpha: 1)
])
wordmark.addAttribute(.foregroundColor,
                      value: NSColor(srgbRed: 140 / 255, green: 106 / 255, blue: 54 / 255, alpha: 1),
                      range: NSRange(location: 1, length: 1))
let textSize = wordmark.size()
wordmark.draw(at: NSPoint(x: (CGFloat(size) - textSize.width) / 2,
                         y: (CGFloat(size) - textSize.height) / 2))
NSGraphicsContext.restoreGraphicsState()
guard let image = context.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the wordmark")
}
try png.write(to: URL(fileURLWithPath: output), options: .atomic)
