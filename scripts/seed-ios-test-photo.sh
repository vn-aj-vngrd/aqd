#!/bin/bash
# Synthetic asymmetric pixels ONLY: not garment-quality or production demo media.
# Adds one image to Simulator Photos; never clears or replaces the library.
set -euo pipefail
DEVICE="${1:-E5DAD2A0-6375-4737-B33D-3A08A4D9FDAA}"
WORK="$(mktemp -d /tmp/aqd-photo-fixture.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
swift - "$WORK/AQD-synthetic-picker-fixture.png" <<'SWIFT'
import AppKit
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 240, pixelsHigh: 320,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor.systemBlue.setFill()
NSRect(x: 0, y: 0, width: 240, height: 320).fill()
NSColor.systemRed.setFill()
NSRect(x: 0, y: 180, width: 90, height: 140).fill()
NSColor.systemYellow.setFill()
NSRect(x: 150, y: 0, width: 90, height: 70).fill()
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(x: 110, y: 100, width: 40, height: 40)).fill()
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
SWIFT
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl addmedia "$DEVICE" "$WORK/AQD-synthetic-picker-fixture.png"
printf 'Added synthetic asymmetric PNG to Photos on %s (existing library preserved).\n' "$DEVICE"
