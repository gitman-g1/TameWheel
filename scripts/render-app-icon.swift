import AppKit

// Original mouse artwork; no SF Symbols glyphs are embedded in the app icon.
// Regenerate with: xcrun swift scripts/render-app-icon.swift
let project = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let output = project.appendingPathComponent(".build/AppIcon.iconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

func drawIcon(pixels: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: pixels, height: pixels)
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }
    let scale = CGFloat(pixels) / 1024
    context.cgContext.scaleBy(x: scale, y: scale)
    context.imageInterpolation = .high

    let tile = NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880), xRadius: 198, yRadius: 198)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0.10, 0.15, 0.23, 0.20)
    shadow.shadowBlurRadius = 22
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    color(0.96, 0.97, 0.99).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: .white, ending: color(0.86, 0.90, 0.96))!.draw(in: tile, angle: -90)
    color(1, 1, 1, 0.8).setStroke()
    tile.lineWidth = 3
    tile.stroke()

    // A tapered, softly asymmetric body and an oversized wheel make a distinct mark.
    let body = NSBezierPath()
    body.move(to: NSPoint(x: 514, y: 805))
    body.curve(to: NSPoint(x: 681, y: 638), controlPoint1: NSPoint(x: 626, y: 805), controlPoint2: NSPoint(x: 675, y: 736))
    body.curve(to: NSPoint(x: 710, y: 422), controlPoint1: NSPoint(x: 687, y: 552), controlPoint2: NSPoint(x: 710, y: 492))
    body.curve(to: NSPoint(x: 509, y: 219), controlPoint1: NSPoint(x: 710, y: 293), controlPoint2: NSPoint(x: 629, y: 219))
    body.curve(to: NSPoint(x: 305, y: 420), controlPoint1: NSPoint(x: 381, y: 219), controlPoint2: NSPoint(x: 305, y: 291))
    body.curve(to: NSPoint(x: 343, y: 638), controlPoint1: NSPoint(x: 305, y: 509), controlPoint2: NSPoint(x: 337, y: 562))
    body.curve(to: NSPoint(x: 514, y: 805), controlPoint1: NSPoint(x: 350, y: 741), controlPoint2: NSPoint(x: 408, y: 805))
    body.close()

    color(0.16, 0.19, 0.25).setStroke()
    body.lineWidth = pixels <= 32 ? 36 : 30
    body.lineJoinStyle = .round
    body.stroke()

    let wheel = NSBezierPath(roundedRect: NSRect(x: 470, y: 570, width: 84, height: 162), xRadius: 42, yRadius: 42)
    NSGradient(starting: color(0.22, 0.66, 1), ending: color(0.02, 0.36, 0.92))!.draw(in: wheel, angle: -90)
    if pixels >= 64 {
        let glint = NSBezierPath(roundedRect: NSRect(x: 490, y: 640, width: 10, height: 60), xRadius: 5, yRadius: 5)
        color(1, 1, 1, 0.5).setFill()
        glint.fill()
    }
    return bitmap.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    for density in [1, 2] {
        let suffix = density == 2 ? "@2x" : ""
        let data = try drawIcon(pixels: size * density)
        try data.write(to: output.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
print("Rendered: \(output.path)")
