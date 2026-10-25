import AppKit
import QuartzCore
import ServiceManagement
import SwiftUI

// MARK: - Settings (persisted in UserDefaults)

enum Effect: String, CaseIterable, Identifiable {
    case sparkles, circle, ripple, rays, dashes, firework, willow, doubleRing, random
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sparkles: "Sparkles"
        case .circle: "Circle pop"
        case .ripple: "Ripple rings"
        case .rays: "Light rays"
        case .dashes: "Dash burst"
        case .firework: "Firework"
        case .willow: "Firework – willow"
        case .doubleRing: "Firework – double ring"
        case .random: "Surprise me"
        }
    }
    var isFirework: Bool { [.firework, .willow, .doubleRing].contains(self) }
}

enum Theme: String, CaseIterable, Identifiable {
    case magic, neon, gold, rainbow, pink, ice, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .magic: "Magic"
        case .neon: "Neon"
        case .gold: "Gold"
        case .rainbow: "Rainbow"
        case .pink: "Pink"
        case .ice: "Ice"
        case .custom: "Custom"
        }
    }
}

enum Shape: String, CaseIterable, Identifiable {
    case mixed, stars, dots, hearts
    var id: String { rawValue }
    var label: String {
        switch self {
        case .mixed: "Stars + dots"
        case .stars: "Stars"
        case .dots: "Dots"
        case .hearts: "Hearts"
        }
    }
}

enum Key {
    static let enabled = "enabled", effect = "effect", glow = "glow"
    static let theme = "theme", customColor = "customColor", shape = "shape"
    static let count = "count", size = "size", speed = "speed", gravity = "gravity", lifetime = "lifetime"
    static let trail = "trail", rightClick = "rightClick"
}

let defaultSettings: [String: Any] = [
    Key.enabled: true, Key.effect: Effect.firework.rawValue, Key.glow: true, Key.theme: Theme.neon.rawValue, Key.customColor: "#FFD45A", Key.shape: Shape.mixed.rawValue,
    Key.count: 30.0, Key.size: 0.5, Key.speed: 0.5, Key.gravity: 1.0, Key.lifetime: 0.5,
    Key.trail: true, Key.rightClick: true,
]

let prefs = UserDefaults.standard

func colors(for theme: Theme) -> [NSColor] {
    func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor { NSColor(red: r, green: g, blue: b, alpha: 1) }
    switch theme {
    case .magic: return [rgb(1, 0.84, 0.35), rgb(1, 0.96, 0.8), rgb(1, 0.55, 0.8), rgb(0.6, 0.86, 1), rgb(0.78, 0.63, 1)]
    case .neon: return [rgb(1, 0.1, 0.8), rgb(0, 1, 1), rgb(0.25, 1, 0.3), rgb(1, 0.95, 0), rgb(0.6, 0.3, 1), rgb(1, 0.4, 0.1)]
    case .gold: return [rgb(1, 0.84, 0.3), rgb(1, 0.93, 0.6), rgb(1, 0.72, 0.2), rgb(1, 0.98, 0.88)]
    case .rainbow: return [rgb(1, 0.3, 0.3), rgb(1, 0.6, 0.2), rgb(1, 0.92, 0.3), rgb(0.4, 0.9, 0.4), rgb(0.3, 0.7, 1), rgb(0.7, 0.4, 1)]
    case .pink: return [rgb(1, 0.5, 0.75), rgb(1, 0.75, 0.88), rgb(0.95, 0.35, 0.6), rgb(1, 0.92, 0.96)]
    case .ice: return [rgb(0.6, 0.86, 1), rgb(0.85, 0.95, 1), rgb(0.45, 0.7, 1), rgb(1, 1, 1)]
    case .custom:
        let base = NSColor(hex: prefs.string(forKey: Key.customColor) ?? "") ?? .systemYellow
        return [base, base.blended(withFraction: 0.5, of: .white) ?? base]
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }

    var hex: String {
        let c = usingColorSpace(.sRGB) ?? self
        return String(format: "#%02X%02X%02X", Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
    }
}

// MARK: - Sprites

func makeContext(_ size: Int) -> CGContext {
    CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func drawGlow(_ ctx: CGContext, center c: CGFloat, radius: CGFloat, alpha: CGFloat) {
    let colors = [CGColor(red: 1, green: 1, blue: 1, alpha: alpha),
                  CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    let p = CGPoint(x: c, y: c)
    ctx.drawRadialGradient(g, startCenter: p, startRadius: 0, endCenter: p, endRadius: radius, options: [])
}

/// A four-pointed star with curved, pinched arms and a soft glow.
func makeStar(size: Int = 96) -> CGImage {
    let ctx = makeContext(size)
    let c = CGFloat(size) / 2
    drawGlow(ctx, center: c, radius: c * 0.55, alpha: 0.55)

    let r = c * 0.98, w = c * 0.12
    let path = CGMutablePath()
    path.move(to: CGPoint(x: c, y: c + r))
    path.addQuadCurve(to: CGPoint(x: c + r, y: c), control: CGPoint(x: c + w, y: c + w))
    path.addQuadCurve(to: CGPoint(x: c, y: c - r), control: CGPoint(x: c + w, y: c - w))
    path.addQuadCurve(to: CGPoint(x: c - r, y: c), control: CGPoint(x: c - w, y: c - w))
    path.addQuadCurve(to: CGPoint(x: c, y: c + r), control: CGPoint(x: c - w, y: c + w))
    ctx.addPath(path)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillPath()
    return ctx.makeImage()!
}

/// A small round glowing dot.
func makeDot(size: Int = 48) -> CGImage {
    let ctx = makeContext(size)
    let c = CGFloat(size) / 2
    drawGlow(ctx, center: c, radius: c, alpha: 1)
    return ctx.makeImage()!
}

/// A heart with a soft glow (drawn upright in a y-up context).
func makeHeart(size: Int = 96) -> CGImage {
    let ctx = makeContext(size)
    let s = CGFloat(size), c = s / 2
    drawGlow(ctx, center: c, radius: c * 0.9, alpha: 0.35)

    let path = CGMutablePath()
    path.move(to: CGPoint(x: c, y: s * 0.18))
    path.addCurve(to: CGPoint(x: s * 0.16, y: s * 0.62), control1: CGPoint(x: s * 0.36, y: s * 0.36), control2: CGPoint(x: s * 0.16, y: s * 0.46))
    path.addCurve(to: CGPoint(x: c, y: s * 0.66), control1: CGPoint(x: s * 0.16, y: s * 0.84), control2: CGPoint(x: s * 0.44, y: s * 0.86))
    path.addCurve(to: CGPoint(x: s * 0.84, y: s * 0.62), control1: CGPoint(x: s * 0.56, y: s * 0.86), control2: CGPoint(x: s * 0.84, y: s * 0.84))
    path.addCurve(to: CGPoint(x: c, y: s * 0.18), control1: CGPoint(x: s * 0.84, y: s * 0.46), control2: CGPoint(x: s * 0.64, y: s * 0.36))
    ctx.addPath(path)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillPath()
    return ctx.makeImage()!
}

let starImage = makeStar()
let dotImage = makeDot()
let heartImage = makeHeart()

// MARK: - Particles

/// Burst kind: a click explodes outward, a drag leaves a gentle trail.
enum Burst { case click, trail }

/// Sprites tinted per color, cached so each burst reuses them.
var tintCache: [String: CGImage] = [:]

func tinted(_ image: CGImage, _ name: String, _ color: NSColor) -> CGImage {
    let key = name + color.hex
    if let cached = tintCache[key] { return cached }
    let ctx = makeContext(image.width)
    let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
    ctx.draw(image, in: rect)
    ctx.setBlendMode(.sourceIn)
    ctx.setFillColor(color.cgColor)
    ctx.fill(rect)
    let result = ctx.makeImage()!
    tintCache[key] = result
    return result
}

/// Builds one layer per sparkle with its animation already attached.
/// Directions are stratified around the full circle so every side gets the same share.
func makeParticles(_ kind: Burst, at origin: CGPoint) -> (layers: [CALayer], maxLife: Double) {
    let theme = Theme(rawValue: prefs.string(forKey: Key.theme) ?? "") ?? .magic
    let shape = Shape(rawValue: prefs.string(forKey: Key.shape) ?? "") ?? .mixed
    let size = prefs.double(forKey: Key.size)
    let speed = prefs.double(forKey: Key.speed)
    let gravity = -280 * prefs.double(forKey: Key.gravity) // layer y-axis points up
    let lifetime = prefs.double(forKey: Key.lifetime)
    let count = kind == .click ? Int(prefs.double(forKey: Key.count)) : 4
    let velocity = (kind == .click ? 260 : 50) * speed

    // (image, name, share, base scale); a 96px sprite at 2x is 48pt at scale 1.
    let sprites: [(CGImage, String, Double, Double)] = switch shape {
    case .mixed: [(starImage, "star", 0.7, 0.42), (dotImage, "dot", 0.3, 0.35)]
    case .stars: [(starImage, "star", 1, 0.42)]
    case .dots: [(dotImage, "dot", 1, 0.4)]
    case .hearts: [(heartImage, "heart", 1, 0.38)]
    }
    let palette = colors(for: theme)
    let spinRange = shape == .hearts ? 1.5 : 5.0
    let offset = Double.random(in: 0..<(2 * .pi))

    var layers: [CALayer] = []
    var maxLife = 0.0
    for i in 0..<count {
        let angle = offset + (Double(i) + .random(in: 0..<1)) / Double(count) * 2 * .pi
        let v = velocity * .random(in: 0.3...1.7)
        let vx = cos(angle) * v, vy = sin(angle) * v
        let life = lifetime * .random(in: 0.6...1.4)
        maxLife = max(maxLife, life)

        let (image, name, _, baseScale) = Double.random(in: 0..<1) < sprites[0].2 ? sprites[0] : sprites[sprites.count - 1]
        let scale = baseScale * size * .random(in: 0.5...1.5)
        let side = CGFloat(image.width) / 2 * scale

        let layer = CALayer()
        layer.contents = tinted(image, name, palette.randomElement()!)
        layer.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        layer.position = origin
        layer.opacity = 0

        // Projectile path sampled along the particle's life.
        var points: [NSValue] = []
        for step in 0...12 {
            let t = life * Double(step) / 12
            points.append(NSValue(point: NSPoint(x: origin.x + vx * t, y: origin.y + vy * t + 0.5 * gravity * t * t)))
        }
        let move = CAKeyframeAnimation(keyPath: "position")
        move.values = points

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = Double.random(in: 0.7...1)
        fade.toValue = 0

        let shrink = CABasicAnimation(keyPath: "transform.scale")
        shrink.fromValue = 1
        shrink.toValue = max(0.05, 1 - 0.6 * life)

        let start = Double.random(in: 0..<(2 * .pi))
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = shape == .hearts ? 0 : start
        spin.toValue = (shape == .hearts ? 0 : start) + Double.random(in: -spinRange / 2...spinRange / 2) * life

        let group = CAAnimationGroup()
        group.animations = [move, fade, shrink, spin]
        group.duration = life
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        layer.add(group, forKey: "sparkle")
        layers.append(layer)
    }
    return (layers, maxLife)
}

// MARK: - Shape effects (circle, ripple, rays, dashes)

func makeShapeEffect(_ effect: Effect, at origin: CGPoint) -> (layers: [CALayer], maxLife: Double) {
    let theme = Theme(rawValue: prefs.string(forKey: Key.theme) ?? "") ?? .magic
    let palette = colors(for: theme).shuffled()
    let size = prefs.double(forKey: Key.size)
    let duration = min(3, max(0.25, prefs.double(forKey: Key.lifetime) * 0.6) / prefs.double(forKey: Key.speed))
    let count = prefs.double(forKey: Key.count)
    let glow = prefs.bool(forKey: Key.glow)
    let lineWidth = 3 * max(0.7, size)

    // Shape layers have zero bounds at `origin`, so paths are drawn around (0, 0) and scale outward from the click.
    func shape(_ path: CGPath, _ color: NSColor, fill: Bool = false) -> CAShapeLayer {
        let l = CAShapeLayer()
        l.path = path
        l.fillColor = fill ? color.withAlphaComponent(glow ? 0.55 : 0.85).cgColor : nil
        l.strokeColor = fill && !glow ? nil : color.cgColor
        l.lineWidth = fill ? 2 : lineWidth
        l.lineCap = .round
        if glow {
            l.shadowColor = color.cgColor
            l.shadowRadius = 7
            l.shadowOpacity = 1
            l.shadowOffset = .zero
        }
        return l
    }
    func circle(_ r: CGFloat) -> CGPath { CGPath(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r), transform: nil) }
    func line(_ angle: Double, from r1: Double, to r2: Double) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: cos(angle) * r1, y: sin(angle) * r1))
        p.addLine(to: CGPoint(x: cos(angle) * r2, y: sin(angle) * r2))
        return p
    }
    func keyframes(_ keyPath: String, _ values: [Double], _ times: [Double]) -> CAKeyframeAnimation {
        let a = CAKeyframeAnimation(keyPath: keyPath)
        a.values = values
        a.keyTimes = times.map { NSNumber(value: $0) }
        return a
    }
    func animate(_ layer: CALayer, delay: Double = 0, _ animations: [CAAnimation]) {
        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = duration
        group.beginTime = CACurrentMediaTime() + delay
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .both
        group.isRemovedOnCompletion = false
        layer.position = origin
        layer.opacity = 0
        layer.add(group, forKey: "effect")
    }

    var layers: [CALayer] = []
    switch effect {
    case .circle:
        let l = shape(circle(28 * size), palette[0], fill: true)
        animate(l, [keyframes("transform.scale", [0.2, 1.3], [0, 1]), keyframes("opacity", [0.95, 0.8, 0], [0, 0.4, 1])])
        layers.append(l)

    case .ripple:
        for i in 0..<3 {
            let l = shape(circle(36 * size), palette[i % palette.count])
            animate(l, delay: Double(i) * duration * 0.18,
                    [keyframes("transform.scale", [0.1, 1], [0, 1]), keyframes("opacity", [1, 1, 0], [0, 0.5, 1])])
            layers.append(l)
        }

    case .rays:
        let n = min(28, max(8, Int(count / 3)))
        for i in 0..<n {
            let angle = Double(i) / Double(n) * 2 * .pi
            let outer = (i.isMultiple(of: 2) ? 46 : 36) * size
            let l = shape(line(angle, from: 12 * size, to: outer), palette[i % palette.count])
            animate(l, [keyframes("strokeEnd", [0, 1, 1], [0, 0.45, 1]),
                        keyframes("strokeStart", [0, 0, 1], [0, 0.35, 1]),
                        keyframes("opacity", [1, 1, 0], [0, 0.75, 1])])
            layers.append(l)
        }

    case .dashes:
        // Two staggered rings of short dashes that fly outward together.
        let n = min(20, max(8, Int(count / 4)))
        let group = CALayer()
        for ring in 0..<2 {
            let (r1, r2) = ring == 0 ? (14 * size, 22 * size) : (27 * size, 35 * size)
            for i in 0..<n {
                let angle = (Double(i) + (ring == 0 ? 0 : 0.5)) / Double(n) * 2 * .pi
                let dash = shape(line(angle, from: r1, to: r2), palette[(i + ring) % palette.count])
                dash.lineWidth = lineWidth * 0.8
                group.addSublayer(dash)
            }
        }
        animate(group, [keyframes("transform.scale", [0.5, 1.3], [0, 1]), keyframes("opacity", [1, 1, 0], [0, 0.55, 1])])
        layers.append(group)

    default:
        break
    }
    return (layers, duration * 1.4 + 0.1)
}

// MARK: - Fireworks

/// Sparks fly with air drag and gravity; each spark drags a few fading "ghost" copies
/// along the same path a moment later, which reads as a glowing streak.
func makeFirework(_ effect: Effect, at origin: CGPoint) -> (layers: [CALayer], maxLife: Double) {
    let theme = Theme(rawValue: prefs.string(forKey: Key.theme) ?? "") ?? .magic
    let palette = colors(for: theme).shuffled()
    let size = prefs.double(forKey: Key.size)
    let speed = prefs.double(forKey: Key.speed)
    let gravity = prefs.double(forKey: Key.gravity)
    let lifeScale = prefs.double(forKey: Key.lifetime) / 0.9
    let count = prefs.double(forKey: Key.count)
    let drag = 2.2
    let now = CACurrentMediaTime()

    var layers: [CALayer] = []
    var maxLife = 0.0

    /// Position after `t` seconds for launch velocity (vx, vy) and vertical acceleration `a` (y-up).
    func position(_ vx: Double, _ vy: Double, _ a: Double, _ t: Double) -> CGPoint {
        let f = (1 - exp(-drag * t)) / drag
        return CGPoint(x: origin.x + vx * f, y: origin.y + a * t / drag + (vy - a / drag) * f)
    }

    func layer(_ image: CGImage, _ name: String, _ color: NSColor, scale: Double, at p: CGPoint) -> CALayer {
        let l = CALayer()
        l.contents = tinted(image, name, color)
        let side = CGFloat(image.width) / 2 * scale
        l.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        l.position = p
        l.opacity = 0
        layers.append(l)
        return l
    }

    func play(_ l: CALayer, delay: Double, duration: Double, _ animations: [CAAnimation]) {
        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = duration
        group.beginTime = now + delay
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        l.add(group, forKey: "firework")
        maxLife = max(maxLife, delay + duration)
    }

    func keyframes(_ keyPath: String, _ values: [Any], _ times: [Double]? = nil) -> CAKeyframeAnimation {
        let a = CAKeyframeAnimation(keyPath: keyPath)
        a.values = values
        if let times { a.keyTimes = times.map { NSNumber(value: $0) } }
        return a
    }

    /// One spark plus `ghosts` trailing copies.
    func spark(angle: Double, velocity v: Double, life: Double, accel a: Double, color: NSColor,
               head: (CGImage, String), scale: Double, ghosts: Int, ghostGap: Double, flicker: Bool) {
        let vx = cos(angle) * v, vy = sin(angle) * v
        let path = (0...16).map { NSValue(point: position(vx, vy, a, life * Double($0) / 16)) }
        for g in 0...ghosts {
            let k = Double(g) / Double(max(ghosts, 1))
            let (image, name) = g == 0 ? head : (dotImage, "dot")
            let o = g == 0 ? 1 : 0.75 * (1 - k)
            let l = layer(image, name, color, scale: scale * (g == 0 ? 1 : 0.8 - 0.45 * k), at: origin)
            let fade = flicker && g == 0
                ? keyframes("opacity", [o, o, o * 0.3, o, o * 0.2, o * 0.8, 0], [0, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
                : keyframes("opacity", [o, o * 0.85, 0], [0, 0.6, 1])
            play(l, delay: Double(g) * ghostGap, duration: life,
                 [keyframes("position", path), fade, keyframes("transform.scale", [1, 0.35])])
        }
    }

    /// Bright white pop at the launch point.
    func flash(scale: Double) {
        let l = layer(dotImage, "dot", .white, scale: scale * size, at: origin)
        play(l, delay: 0, duration: 0.3, [keyframes("transform.scale", [0.3, 2.2]), keyframes("opacity", [1, 0])])
    }

    let star = (starImage, "star"), dot = (dotImage, "dot")

    switch effect {
    case .firework:
        // Classic peony: an even sphere of sparks in two alternating colors that twinkle out.
        let n = max(16, Int(count))
        let offset = Double.random(in: 0..<(2 * .pi))
        flash(scale: 1.6)
        for i in 0..<n {
            spark(angle: offset + (Double(i) + .random(in: 0..<1)) / Double(n) * 2 * .pi,
                  velocity: 240 * speed * .random(in: 0.85...1.05), life: 1.1 * lifeScale * .random(in: 0.9...1.1),
                  accel: -150 * gravity, color: palette[i % min(2, palette.count)],
                  head: star, scale: 0.32 * size, ghosts: 4, ghostGap: 0.035, flicker: true)
        }

    case .willow:
        // Slow, heavy sparks with long trails that droop like willow branches.
        let n = max(14, Int(count * 0.6))
        flash(scale: 1.4)
        for i in 0..<n {
            spark(angle: (Double(i) + .random(in: 0..<1)) / Double(n) * 2 * .pi,
                  velocity: 160 * speed * .random(in: 0.8...1.1), life: 1.9 * lifeScale * .random(in: 0.9...1.1),
                  accel: -260 * gravity, color: palette[i % min(2, palette.count)],
                  head: dot, scale: 0.55 * size, ghosts: 7, ghostGap: 0.05, flicker: false)
        }

    case .doubleRing:
        // Two crisp concentric rings: sparks at near-identical speeds keep the ring shape.
        let n = max(16, Int(count * 0.7))
        let colorB = palette[1 % palette.count]
        flash(scale: 1.6)
        for (ring, (v, color, num)) in [(120.0, palette[0], n / 2), (240.0, colorB, n)].enumerated() {
            let offset = ring == 0 ? 0 : .pi / Double(num)
            for i in 0..<num {
                spark(angle: offset + Double(i) / Double(num) * 2 * .pi,
                      velocity: v * speed * .random(in: 0.98...1.02), life: 1.0 * lifeScale,
                      accel: -90 * gravity, color: color,
                      head: star, scale: 0.3 * size, ghosts: 3, ghostGap: 0.03, flicker: false)
            }
        }

    default:
        break
    }
    return (layers, maxLife + 0.1)
}

// MARK: - Overlay window (one per display)

final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        setFrame(screen.frame, display: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        level = .screenSaver // above the menu bar, Dock and full-screen apps
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.wantsLayer = true
        contentView = view
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// `point` is in global screen coordinates (bottom-left origin).
    func sparkle(at point: NSPoint, _ kind: Burst) {
        guard let root = contentView?.layer else { return }
        let origin = CGPoint(x: point.x - frame.minX, y: point.y - frame.minY)
        var effect = Effect(rawValue: prefs.string(forKey: Key.effect) ?? "") ?? .firework
        if effect == .random { effect = Effect.allCases.filter { $0 != .random }.randomElement()! }
        // Drag trails are always small sparkles; the chosen effect plays on clicks.
        let (layers, maxLife) = kind == .trail || effect == .sparkles ? makeParticles(kind, at: origin)
            : effect.isFirework ? makeFirework(effect, at: origin)
            : makeShapeEffect(effect, at: origin)

        let burst = CALayer()
        burst.frame = root.bounds
        layers.forEach(burst.addSublayer)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        root.addSublayer(burst)
        CATransaction.commit()

        DispatchQueue.main.asyncAfter(deadline: .now() + maxLife + 0.1) { burst.removeFromSuperlayer() }
    }
}

// MARK: - Settings window

/// Wraps the macOS login-item registration so SwiftUI can bind a toggle to it.
final class LoginItem: ObservableObject {
    var isOn: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            objectWillChange.send()
        }
    }
}

struct SettingsView: View {
    @AppStorage(Key.enabled) var enabled = true
    @AppStorage(Key.effect) var effect = Effect.firework.rawValue
    @AppStorage(Key.glow) var glow = true
    @AppStorage(Key.theme) var theme = Theme.neon.rawValue
    @AppStorage(Key.customColor) var customColor = "#FFD45A"
    @AppStorage(Key.shape) var shape = Shape.mixed.rawValue
    @AppStorage(Key.count) var count = 30.0
    @AppStorage(Key.size) var size = 0.5
    @AppStorage(Key.speed) var speed = 0.5
    @AppStorage(Key.gravity) var gravity = 1.0
    @AppStorage(Key.lifetime) var lifetime = 0.5
    @AppStorage(Key.trail) var trail = true
    @AppStorage(Key.rightClick) var rightClick = true
    @StateObject var login = LoginItem()

    var preview: () -> Void

    var body: some View {
        Form {
            Section {
                Toggle("Effects enabled", isOn: $enabled)
                Toggle("Launch at login", isOn: $login.isOn)
            }
            Section("Look") {
                Picker("Click effect", selection: $effect) {
                    ForEach(Effect.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Colors", selection: $theme) {
                    ForEach(Theme.allCases) { Text($0.label).tag($0.rawValue) }
                }
                if theme == Theme.custom.rawValue {
                    ColorPicker("Custom color", selection: Binding(
                        get: { Color(nsColor: NSColor(hex: customColor) ?? .systemYellow) },
                        set: { customColor = NSColor($0).hex }
                    ), supportsOpacity: false)
                }
                if effect == Effect.sparkles.rawValue || effect == Effect.random.rawValue {
                    Picker("Sparkle shape", selection: $shape) {
                        ForEach(Shape.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                }
                Toggle("Neon glow", isOn: $glow)
            }
            Section("Motion") {
                slider("Amount", $count, 10...150, "%.0f")
                slider("Size", $size, 0.4...2.5, "%.1f×")
                slider("Speed", $speed, 0.3...2.5, "%.1f×")
                slider("Gravity", $gravity, -1...3, "%.1f×")
                slider("Duration", $lifetime, 0.3...2.5, "%.1fs")
            }
            Section("Triggers") {
                Toggle("Sparkle trail while dragging", isOn: $trail)
                Toggle("Sparkle on right-click", isOn: $rightClick)
            }
            Section {
                HStack {
                    Button("Reset to Defaults") {
                        defaultSettings.keys.forEach { prefs.removeObject(forKey: $0) }
                    }
                    Spacer()
                    Button("Preview ✨", action: preview).keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize()
    }

    func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ fmt: String) -> some View {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range)
                Text(String(format: fmt, value.wrappedValue))
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var windows: [OverlayWindow] = []
    var monitors: [Any] = []
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    var toggleItem: NSMenuItem!
    var lastTrail = NSPoint.zero

    func applicationDidFinishLaunching(_ note: Notification) {
        prefs.register(defaults: defaultSettings)
        buildWindows()
        NotificationCenter.default.addObserver(self, selector: #selector(buildWindows),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)

        // Global monitors see clicks in other apps; local ones see clicks in our own windows.
        // Mouse events don't require Accessibility permission.
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseDragged]
        if let m = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] e in self?.handle(e) }) {
            monitors.append(m)
        }
        if let m = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] e in self?.handle(e); return e }) {
            monitors.append(m)
        }

        setupStatusItem()
    }

    @objc func buildWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
        windows.forEach { $0.orderFrontRegardless() }
    }

    func sparkle(at p: NSPoint, _ kind: Burst) {
        windows.first(where: { NSMouseInRect(p, $0.frame, false) })?.sparkle(at: p, kind)
    }

    func handle(_ event: NSEvent) {
        guard prefs.bool(forKey: Key.enabled) else { return }
        let p = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDragged:
            guard prefs.bool(forKey: Key.trail), hypot(p.x - lastTrail.x, p.y - lastTrail.y) >= 8 else { return }
            sparkle(at: p, .trail)
        case .rightMouseDown, .otherMouseDown:
            guard prefs.bool(forKey: Key.rightClick) else { return }
            sparkle(at: p, .click)
        default:
            sparkle(at: p, .click)
        }
        lastTrail = p
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "✨"

        let menu = NSMenu()
        menu.delegate = self
        toggleItem = NSMenuItem(title: "Clickle On", action: #selector(toggle), keyEquivalent: "")
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Clickle", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        toggleItem.state = prefs.bool(forKey: Key.enabled) ? .on : .off
    }

    @objc func toggle() {
        prefs.set(!prefs.bool(forKey: Key.enabled), forKey: Key.enabled)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView { [weak self] in
                guard let self, let w = self.settingsWindow else { return }
                // Sparkle just above the settings window so it isn't hidden behind it.
                self.sparkle(at: NSPoint(x: w.frame.midX, y: w.frame.maxY + 60), .click)
            }
            let w = NSWindow(contentViewController: NSHostingController(rootView: view))
            w.title = "Clickle Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // menu-bar only, no Dock icon
app.run()
