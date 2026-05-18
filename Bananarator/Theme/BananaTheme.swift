import SwiftUI

// MARK: - BananaTheme
/// Central design system for Bananarator: a campy, party-bright, sticker-card aesthetic
/// drawn from the dapper-top-hat-banana app icon and splash screen.
///
/// Use these tokens everywhere; do not hardcode colors or shadows in feature views.
enum BananaTheme {

    // MARK: Palette
    /// Hero "banana" yellow (#FFD93D). Use sparingly as a feature accent or highlight.
    static let bananaYellow      = Color(hex: 0xFFD93D)
    /// Deep chocolate brown from the banana's top hat / mustache (#3B2417).
    static let dapperBrown       = Color(hex: 0x3B2417)
    /// Bright cobalt party blue (#2390CC) — primary background hue.
    static let partyBlue         = Color(hex: 0x2390CC)
    /// Deep ocean blue (#1564A8), used as the dark end of the background gradient.
    static let partyBlueDeep     = Color(hex: 0x1564A8)
    /// Hot pink accent (#FF4D8A) — the main "tap me" color.
    static let partyPink         = Color(hex: 0xFF4D8A)
    /// Electric purple (#8A4DFF) — paired with pink for decorate / sticker actions.
    static let partyPurple       = Color(hex: 0x8A4DFF)
    /// Bright party green (#2ECC71) — share / success / "owned".
    static let partyGreen        = Color(hex: 0x2ECC71)
    /// Warm cream (#FFF6E0) used for sticker-card surfaces.
    static let cream             = Color(hex: 0xFFF6E0)
    /// Tomato-red banner accent (#FF4747).
    static let bannerRed         = Color(hex: 0xFF4747)

    /// The app-wide tint. Pink reads "party / queer / playful" against the cobalt backdrop.
    static let accent: Color = .partyPink

    // MARK: Gradients

    /// The signature cobalt-to-sky party backdrop, as used in the splash.
    static let partyBackground = LinearGradient(
        colors: [partyBlue, partyBlueDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Radial party glow, used for "hero" backgrounds.
    static let partyRadial = RadialGradient(
        colors: [Color(hex: 0x4FB6E5), partyBlue, partyBlueDeep],
        center: .top,
        startRadius: 20,
        endRadius: 700
    )

    /// Pink → purple ramp for "premium" CTA buttons.
    static let pinkPurple = LinearGradient(
        colors: [partyPink, partyPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Yellow → cream ramp for the wordmark banner.
    static let bananaSheen = LinearGradient(
        colors: [bananaYellow, Color(hex: 0xFFEFA1)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: Shape

    /// Big, chunky corner radius for cards and sheets.
    static let cardCornerRadius: CGFloat = 24
    /// Medium radius for buttons and chips.
    static let chipCornerRadius: CGFloat = 16

    // MARK: Shadows

    /// The drop shadow used on the white sticker-cards in the splash.
    struct CardShadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    static let cardShadow = CardShadow(
        color: Color.black.opacity(0.18),
        radius: 14,
        x: 0,
        y: 8
    )

    static let softShadow = CardShadow(
        color: Color.black.opacity(0.10),
        radius: 8,
        x: 0,
        y: 4
    )

    // MARK: Type ramp (all SF Pro Rounded)

    static func display(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Color hex init

extension Color {
    /// Initialize from a 0xRRGGBB hex literal.
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double((hex >>  0) & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    // Convenience aliases so call sites can read `Color.partyPink` etc.
    static let bananaYellow  = BananaTheme.bananaYellow
    static let dapperBrown   = BananaTheme.dapperBrown
    static let partyBlue     = BananaTheme.partyBlue
    static let partyBlueDeep = BananaTheme.partyBlueDeep
    static let partyPink     = BananaTheme.partyPink
    static let partyPurple   = BananaTheme.partyPurple
    static let partyGreen    = BananaTheme.partyGreen
    static let cream         = BananaTheme.cream
    static let bannerRed     = BananaTheme.bannerRed
}

// MARK: - Shadow modifier helper

extension View {
    /// Applies a `BananaTheme.CardShadow`.
    func bananaShadow(_ shadow: BananaTheme.CardShadow = BananaTheme.cardShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
