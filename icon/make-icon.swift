// Draws the Clickle app icon: a cursor clicking into a neon firework burst.
// Usage: swift make-icon.swift <output.png>
import AppKit

let size: CGFloat = 1024
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Work in y-down coordinates, like a design tool.
ctx.translateBy(x: 0, y: size)
ctx.scaleBy(x: 1, y: -1)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// MARK: Background — macOS icon grid: 824pt rounded square centered on a 1024 canvas.

let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 12), blur: 28, color: rgb(0, 0, 0, 0.45))
ctx.addPath(tilePath)
ctx.setFillColor(rgb(0.04, 0.02, 0.1))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(tilePath)
ctx.clip()
let sky = CGGradient(colorsSpace: nil, colors: [rgb(0.2, 0.08, 0.38), rgb(0.07, 0.03, 0.17), rgb(0.02, 0.01, 0.06)] as CFArray,
                     locations: [0, 0.55, 1])!
let burst = CGPoint(x: 445, y: 440)
ctx.drawRadialGradient(sky, startCenter: burst, startRadius: 0, endCenter: burst, endRadius: 720, options: .drawsAfterEndLocation)

// Faint background stars.
var rng = SystemRandomNumberGenerator()
for _ in 0..<40 {
    let p = CGPoint(x: .random(in: 120...904, using: &rng), y: .random(in: 120...904, using: &rng))
    let r = CGFloat.random(in: 1.5...4, using: &rng)
    ctx.setFillColor(rgb(1, 1, 1, .random(in: 0.15...0.45, using: &rng)))
    ctx.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
}

// MARK: Firework burst — mirrors the app's default effect: Firework in the Neon theme.

let neon = [rgb(1, 0.1, 0.8), rgb(0, 1, 1)] // the two alternating Neon colors

// White flash at the click point.
let flash = CGGradient(colorsSpace: nil, colors: [rgb(1, 1, 1, 0.95), rgb(1, 0.85, 1, 0.4), rgb(1, 0.6, 1, 0)] as CFArray,
                       locations: [0, 0.3, 1])!
ctx.drawRadialGradient(flash, startCenter: burst, startRadius: 0, endCenter: burst, endRadius: 190, options: [])

// Four-pointed star, like the app's spark heads.
func star(at c: CGPoint, radius r: CGFloat, fill: CGColor) {
    let w = r * 0.16
    let p = CGMutablePath()
    p.move(to: CGPoint(x: c.x, y: c.y - r))
    p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + w, y: c.y - w))
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + w, y: c.y + w))
    p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - w, y: c.y + w))
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - w, y: c.y - w))
    ctx.addPath(p)
    ctx.setFillColor(fill)
    ctx.fillPath()
}

// Each spark flies out and droops with gravity, leaving a trail of glowing dots that fade toward the center.
let sparks = 16
for i in 0..<sparks {
    let angle = Double(i) / Double(sparks) * 2 * .pi - .pi / 2
    // Skip sparks hidden behind the cursor (it points down-right from the burst).
    if (0.7...1.65).contains(angle) { continue }
    let color = neon[i % 2]
    let reach: CGFloat = i.isMultiple(of: 2) ? 300 : 255
    let droop: CGFloat = 45
    func point(_ s: CGFloat) -> CGPoint {
        CGPoint(x: burst.x + cos(angle) * reach * s, y: burst.y + sin(angle) * reach * s + droop * s * s)
    }

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 22, color: color)
    let dots = 12
    for d in 0..<dots {
        let s = 0.22 + 0.68 * CGFloat(d) / CGFloat(dots - 1)
        let r = 3 + 8 * s
        let p = point(s)
        ctx.setFillColor(color.copy(alpha: 0.15 + 0.8 * s)!)
        ctx.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
    }

    let head = point(1), size: CGFloat = i.isMultiple(of: 2) ? 32 : 26
    ctx.setShadow(offset: .zero, blur: 30, color: color)
    star(at: head, radius: size, fill: color)
    ctx.restoreGState()
    star(at: head, radius: size * 0.5, fill: rgb(1, 1, 1)) // white-hot core
}

ctx.restoreGState() // end tile clip

// MARK: Cursor — classic arrow with its tip on the burst.

let unit: CGFloat = 23
let arrow: [(CGFloat, CGFloat)] = [(0, 0), (0, 17), (4, 13), (7, 19.5), (9.6, 18.4), (6.7, 12), (12, 12)]
let cursor = CGMutablePath()
cursor.addLines(between: arrow.map { CGPoint(x: burst.x + $0.0 * unit, y: burst.y + $0.1 * unit) })
cursor.closeSubpath()

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 10, height: 18), blur: 26, color: rgb(0, 0, 0, 0.55))
ctx.addPath(cursor)
ctx.setFillColor(rgb(1, 1, 1))
ctx.fillPath()
ctx.restoreGState()

ctx.addPath(cursor)
ctx.setStrokeColor(rgb(0.05, 0.03, 0.12))
ctx.setLineWidth(20)
ctx.setLineJoin(.round)
ctx.strokePath()
ctx.addPath(cursor)
ctx.setFillColor(rgb(1, 1, 1))
ctx.fillPath()

// MARK: Write PNG

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
