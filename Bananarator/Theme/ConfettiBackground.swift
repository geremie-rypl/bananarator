import SwiftUI

// MARK: - ConfettiBackground
/// A lightweight, deterministic confetti + sparkle backdrop in the brand palette.
/// Renders a single Canvas with stable positions seeded from the size so it
/// doesn't reflow on every redraw. Includes a slow `TimelineView` shimmer so
/// the sparkles softly twinkle without burning CPU.
struct ConfettiBackground: View {
    /// Whether to use the party-blue radial as the underlay (true) or be transparent (false).
    var showsGradient: Bool = true
    /// Density factor: 1.0 ≈ 60 confetti / 30 sparkles for a 400×800 frame.
    var density: Double = 1.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if showsGradient {
                    BananaTheme.partyRadial
                        .ignoresSafeArea()
                }
                TimelineView(.animation(minimumInterval: 0.5, paused: false)) { context in
                    Canvas { ctx, size in
                        let now = context.date.timeIntervalSinceReferenceDate
                        drawConfetti(in: ctx, size: size, density: density)
                        drawSparkles(in: ctx, size: size, density: density, time: now)
                    }
                    .blendMode(showsGradient ? .normal : .normal)
                    .allowsHitTesting(false)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    // MARK: Drawing

    private func drawConfetti(in ctx: GraphicsContext, size: CGSize, density: Double) {
        let count = Int(60.0 * density * Double(size.width * size.height) / (400.0 * 800.0))
        let colors: [Color] = [
            .bananaYellow, .partyPink, .partyPurple, .partyGreen, .white, .cream
        ]
        // Use a stable seed so confetti doesn't jitter.
        var rng = SeededRNG(seed: 0xBA1A1A)
        let twoPi: Double = 2 * .pi
        for i in 0..<max(count, 24) {
            let x: CGFloat = rng.nextCG(in: 0...size.width)
            let y: CGFloat = rng.nextCG(in: 0...size.height)
            let w: CGFloat = rng.nextCG(in: 6...18)
            let h: CGFloat = rng.nextCG(in: 3...8)
            let rotation: CGFloat = CGFloat(rng.next(in: 0...twoPi))
            let color = colors[i % colors.count]
            let opacity: Double = rng.next(in: 0.55...0.95)

            let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
            var path = Path(roundedRect: rect, cornerRadius: 2)
            path = path.applying(CGAffineTransform(rotationAngle: rotation))
            path = path.applying(CGAffineTransform(translationX: x, y: y))
            ctx.fill(path, with: .color(color.opacity(opacity)))
        }
    }

    private func drawSparkles(in ctx: GraphicsContext, size: CGSize, density: Double, time: TimeInterval) {
        let count = Int(30.0 * density * Double(size.width * size.height) / (400.0 * 800.0))
        var rng = SeededRNG(seed: 0x5AAA77)
        let twoPi: Double = 2 * .pi
        for i in 0..<max(count, 14) {
            let x: CGFloat = rng.nextCG(in: 0...size.width)
            let y: CGFloat = rng.nextCG(in: 0...size.height)
            let baseSize: Double = rng.next(in: 6...14)
            let phase: Double = rng.next(in: 0...twoPi)
            let twinkle: Double = 0.55 + 0.45 * sin(time * 1.6 + phase)
            let s: Double = baseSize * (0.7 + 0.3 * twinkle)
            let opacity: Double = 0.6 + 0.4 * twinkle

            drawFourPointStar(in: ctx, center: CGPoint(x: x, y: y), size: CGFloat(s),
                              color: i.isMultiple(of: 3) ? .bananaYellow : .white,
                              opacity: opacity)
        }
    }

    private func drawFourPointStar(in ctx: GraphicsContext, center: CGPoint, size: CGFloat,
                                   color: Color, opacity: Double) {
        let r = size / 2
        let inner = r * 0.35
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - r))
        path.addLine(to: CGPoint(x: center.x + inner, y: center.y - inner))
        path.addLine(to: CGPoint(x: center.x + r, y: center.y))
        path.addLine(to: CGPoint(x: center.x + inner, y: center.y + inner))
        path.addLine(to: CGPoint(x: center.x, y: center.y + r))
        path.addLine(to: CGPoint(x: center.x - inner, y: center.y + inner))
        path.addLine(to: CGPoint(x: center.x - r, y: center.y))
        path.addLine(to: CGPoint(x: center.x - inner, y: center.y - inner))
        path.closeSubpath()
        ctx.fill(path, with: .color(color.opacity(opacity)))
    }
}

// MARK: - Tiny deterministic RNG (linear congruential, plenty for cosmetic placement).
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEADBEEF : seed }

    mutating func nextUInt() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        let v = Double(nextUInt() >> 11) / Double(1 << 53)
        return range.lowerBound + v * (range.upperBound - range.lowerBound)
    }

    mutating func nextCG(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat(next(in: Double(range.lowerBound)...Double(range.upperBound)))
    }
}

#Preview {
    ConfettiBackground()
}
