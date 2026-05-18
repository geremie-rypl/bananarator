import SwiftUI

// MARK: - BananaCardStyle
/// The sticker-card look from the splash: cream/white background, big rounded corners,
/// chunky drop shadow, and an optional colored border (pink, blue, yellow…).
struct BananaCardStyle: ViewModifier {
    var fill: AnyShapeStyle
    var borderColor: Color?
    var borderWidth: CGFloat
    var cornerRadius: CGFloat
    var padding: CGFloat?
    var shadow: BananaTheme.CardShadow

    func body(content: Content) -> some View {
        let base = content
            .padding(padding ?? 16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )

        return base
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : borderWidth)
            )
            .bananaShadow(shadow)
    }
}

extension View {
    /// Sticker-card look: white cream surface, rounded corners, drop shadow.
    /// Pass a `borderColor` to add the colored ring used on the splash cards.
    func bananaCard(
        fill: Color = .white,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 4,
        cornerRadius: CGFloat = BananaTheme.cardCornerRadius,
        padding: CGFloat? = 16,
        shadow: BananaTheme.CardShadow = BananaTheme.cardShadow
    ) -> some View {
        self.modifier(BananaCardStyle(
            fill: AnyShapeStyle(fill),
            borderColor: borderColor,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            padding: padding,
            shadow: shadow
        ))
    }

    /// Card variant that takes a gradient fill (e.g. featured cards).
    func bananaCard<S: ShapeStyle>(
        gradient: S,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 4,
        cornerRadius: CGFloat = BananaTheme.cardCornerRadius,
        padding: CGFloat? = 16,
        shadow: BananaTheme.CardShadow = BananaTheme.cardShadow
    ) -> some View {
        self.modifier(BananaCardStyle(
            fill: AnyShapeStyle(gradient),
            borderColor: borderColor,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            padding: padding,
            shadow: shadow
        ))
    }
}

// MARK: - Banana wordmark banner

/// Reusable header banner styled like the splash wordmark: yellow chunky text in a red ribbon.
struct BananaBanner: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(BananaTheme.display(36))
                .foregroundStyle(BananaTheme.bananaSheen)
                .shadow(color: .dapperBrown.opacity(0.45), radius: 0, x: 0, y: 3)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.bannerRed)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white, lineWidth: 4)
                        )
                )
                .bananaShadow(BananaTheme.cardShadow)
                .rotationEffect(.degrees(-2))

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(BananaTheme.body(14))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
        }
    }
}

// MARK: - Lock badge

/// A glowing pink lock used on locked stickers / filters instead of a flat SF Symbol.
struct GlowingLock: View {
    var size: CGFloat = 28
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 1.6, height: size * 1.6)
                .shadow(color: .partyPink.opacity(0.7), radius: 12, x: 0, y: 0)
            Image(systemName: "lock.fill")
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(BananaTheme.pinkPurple)
        }
    }
}

// MARK: - Placeholder asset card

/// Used in place of missing sticker/filter PNGs so the UI doesn't show a blank.
struct BananaPlaceholderArt: View {
    var symbol: String = "questionmark"
    var tint: Color = .partyPink
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BananaTheme.cream)
            // Banana silhouette
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.55, weight: .black))
                .foregroundStyle(Color.bananaYellow.opacity(0.45))
                .rotationEffect(.degrees(35))
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .black, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}
