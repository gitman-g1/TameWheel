import AppKit
import CoreImage
import Vision

// Offline artwork renderer. All drawing coordinates are pixels, measured from the top left.
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let output = root.appendingPathComponent("exports", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let repository = "https://github.com/gitman-g1/TameWheel"
let width = 1080
let height = 1440

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}
let ink = color(0x1D1D1F)
let secondary = color(0x6E6E73)
let blue = color(0x0071E3)
let background = color(0xF5F5F7)

func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
         radius: CGFloat = 0, fill: NSColor, stroke: NSColor? = nil,
         lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h),
                            xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func label(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat,
           weight: NSFont.Weight = .regular, tint: NSColor = ink,
           maxWidth: CGFloat = 936, align: NSTextAlignment = .left) {
    let style = NSMutableParagraphStyle()
    style.alignment = align
    style.lineBreakMode = .byClipping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: tint, .paragraphStyle: style
    ]
    let text = NSAttributedString(string: value, attributes: attributes)
    precondition(text.size().width <= maxWidth + 1, "Text exceeds line: \(value)")
    text.draw(in: NSRect(x: x, y: y, width: maxWidth, height: size * 1.55))
}

func line(_ points: [NSPoint], tint: NSColor, thickness: CGFloat = 2) {
    let path = NSBezierPath()
    path.move(to: points[0])
    points.dropFirst().forEach { path.line(to: $0) }
    path.lineWidth = thickness
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    tint.setStroke()
    path.stroke()
}

func mouseGlyph(x: CGFloat, y: CGFloat, scale: CGFloat = 1, tint: NSColor = ink) {
    box(x, y, 22 * scale, 32 * scale, radius: 10 * scale, fill: .clear,
        stroke: tint, lineWidth: 2 * scale)
    box(x + 9 * scale, y + 5 * scale, 4 * scale, 8 * scale,
        radius: 2 * scale, fill: tint)
}

func shadowed(_ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x1D3552, alpha: 0.10)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -16)
    shadow.set()
    body()
    NSGraphicsContext.restoreGraphicsState()
}

func gradientBox(_ rect: NSRect, radius: CGFloat) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    shadowed {
        NSColor.white.setFill()
        path.fill()
    }
    NSGradient(starting: .white, ending: color(0xE3E5E9))!.draw(in: path, angle: 90)
    color(0xD3D7DD).setStroke()
    path.lineWidth = 2
    path.stroke()
}

func image(_ image: NSImage, in rect: NSRect, source: NSRect = .zero) {
    image.draw(in: rect, from: source, operation: .sourceOver, fraction: 1,
               respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
}

func saveCanvas(name: String, w: Int = width, h: Int = height, draw: () -> Void) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    ctx.cgContext.translateBy(x: 0, y: CGFloat(h))
    ctx.cgContext.scaleBy(x: 1, y: -1)
    // AppKit text/image layout also needs the flipped flag, not only the CTM.
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx.cgContext, flipped: true)
    box(0, 0, CGFloat(w), CGFloat(h), fill: background)
    draw()
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(name))
    print("Exported \(name) · \(w) × \(h)")
}

try saveCanvas(name: "exports/01-cover.png") {
    label("Mac 鼠标，更顺手", x: 72, y: 214, size: 88, weight: .bold)
    label("只调鼠标滚轮，触控板保持原样。", x: 76, y: 338,
          size: 37, tint: secondary)

    // Hardware illustration: familiar wheel on the left, untouched trackpad on the right.
    gradientBox(NSRect(x: 163, y: 570, width: 274, height: 424), radius: 127)
    line([NSPoint(x: 300, y: 574), NSPoint(x: 300, y: 732)], tint: color(0xC5CAD1), thickness: 2)
    box(280, 622, 40, 90, radius: 20, fill: color(0x005FC9))
    box(287, 628, 26, 78, radius: 13, fill: blue)
    for y in stride(from: 643, through: 691, by: 8) {
        line([NSPoint(x: 292, y: y), NSPoint(x: 308, y: y)],
             tint: NSColor.white.withAlphaComponent(0.35), thickness: 1.5)
    }
    gradientBox(NSRect(x: 540, y: 638, width: 380, height: 288), radius: 23)
    box(542, 918, 376, 9, radius: 4, fill: color(0xCBD0D8))

    // Minimal menu bar panel illustration; proportions follow the app's 220 × 44 panel.
    shadowed {
        box(304, 1060, 472, 94, radius: 29, fill: NSColor.white.withAlphaComponent(0.96),
            stroke: color(0xE4E6EA))
    }
    mouseGlyph(x: 333, y: 1089, scale: 1.13)
    label("小滚轮", x: 377, y: 1083, size: 31, weight: .semibold, maxWidth: 200)
    box(641, 1083, 100, 48, radius: 24, fill: blue)
    box(692, 1087, 40, 40, radius: 20, fill: .white)
}

let screenshotURL = root.appendingPathComponent("assets/github-page.png")
guard let screenshot = NSImage(contentsOf: screenshotURL) else { fatalError("Missing GitHub screenshot") }
try saveCanvas(name: "exports/02-github.png") {
    label("TameWheel", x: 72, y: 77, size: 100, weight: .bold, maxWidth: 600)
    label("小滚轮", x: 706, y: 89, size: 82, weight: .bold,
          tint: blue, maxWidth: 302)
    label("代码和功能介绍都在这里。", x: 76, y: 215, size: 32, tint: secondary)
    shadowed {
        box(72, 284, 936, 962, radius: 24, fill: .white, stroke: color(0xDCDEE3))
    }
    box(73, 285, 934, 52, radius: 23, fill: color(0xEBEDF1))
    box(73, 312, 934, 25, fill: color(0xEBEDF1))
    for (i, hex) in [UInt32(0xD8DADF), 0xD8DADF, 0xD8DADF].enumerated() {
        box(CGFloat(96 + i * 22), 303, 12, 12, radius: 6, fill: color(hex))
    }
    label("github.com/gitman-g1/TameWheel", x: 213, y: 295, size: 22,
          tint: secondary, maxWidth: 650, align: .center)
    // Crop the actual screenshot's main column. Keep file names, README and all visible content intact.
    let source = NSRect(x: 220, y: screenshot.size.height - 768, width: 669, height: 738)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: NSRect(x: 73, y: 337, width: 934, height: 908),
                 xRadius: 18, yRadius: 18).addClip()
    image(screenshot, in: NSRect(x: 129, y: 337, width: 822, height: 907), source: source)
    NSGraphicsContext.restoreGraphicsState()
    label("真实项目页面 · 源码已公开", x: 72, y: 1296, size: 23, tint: secondary)
}

let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
qrFilter.setValue(repository.data(using: .utf8)!, forKey: "inputMessage")
qrFilter.setValue("M", forKey: "inputCorrectionLevel")
let qr = qrFilter.outputImage!
let qrCG = CIContext().createCGImage(qr, from: qr.extent)!
let qrImage = NSImage(cgImage: qrCG, size: qr.extent.size)

try saveCanvas(name: "exports/03-link.png") {
    label("在这里，找到小滚轮。", x: 72, y: 95, size: 72, weight: .bold)
    label("喜欢的话，欢迎点个 Star。", x: 76, y: 198, size: 35, tint: secondary)
    shadowed {
        box(174, 348, 732, 650, radius: 38, fill: .white)
    }
    // Quiet zone >= 4 modules, integer scaling and no interpolation keep it easy to scan.
    let qrSize = qr.extent.width * 11
    let qrRect = NSRect(x: (1080 - qrSize) / 2, y: 412, width: qrSize, height: qrSize)
    NSGraphicsContext.current?.imageInterpolation = .none
    qrImage.draw(in: qrRect, from: .zero, operation: .sourceOver, fraction: 1,
                 respectFlipped: true, hints: [.interpolation: NSImageInterpolation.none])
    label("gitman-g1 / TameWheel", x: 210, y: 873, size: 43,
          weight: .semibold, maxWidth: 660, align: .center)
    label("github.com/gitman-g1/TameWheel", x: 72, y: 1084, size: 43,
          weight: .medium, tint: blue, maxWidth: 936, align: .center)
    label("浏览器输入上方地址，或识别二维码", x: 72, y: 1158, size: 28,
          tint: secondary, maxWidth: 936, align: .center)
    label("TameWheel · 小滚轮", x: 72, y: 1264, size: 23, tint: secondary)
}

let barcodeRequest = VNDetectBarcodesRequest()
barcodeRequest.symbologies = [.qr]
try VNImageRequestHandler(url: output.appendingPathComponent("03-link.png")).perform([barcodeRequest])
precondition(barcodeRequest.results?.contains { $0.payloadStringValue == repository } == true,
             "Exported QR code does not decode to the repository URL")
print("QR verified: \(repository)")

try saveCanvas(name: "preview.png", w: 1140, h: 500) {
    for (index, name) in ["01-cover", "02-github", "03-link"].enumerated() {
        let poster = NSImage(contentsOf: output.appendingPathComponent("\(name).png"))!
        image(poster, in: NSRect(x: 18 + index * 378, y: 18, width: 348, height: 464))
    }
}
