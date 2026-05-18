import SwiftUI

// MARK: - BananaCircleButtonStyle
/// The signature chunky "white circle with a colored ring" button from the splash.
/// Use for primary actions: capture, decorate, share.
struct BananaCircleButtonStyle: ButtonStyle {
    enum Tint {
        case pink, purple, blue, green, yellow, red

        var color: Color {
            switch self {
            case .pink:   return .partyPink
            case .purple: return .partyPurple
            case .blue:   return .partyBlue
            case .green:  return .partyGreen
            case .yellow: return .bananaYellow
            case .red:    return .bannerRed
            }
        }
    }

    var tint: Tint = .pink
    var size: CGFloat = 64

    func makeBody(configuration: Configuration) -> some View {
        let scale = configuration.isPressed ? 0.92 : 1.0
        return configuration.label
            .font(.system(size: size * 0.38, weight: .black, design: .rounded))
            .foregroundStyle(tint.color)
            .frame(width: size, height: size)
            .background(
                ZStack {
                    Circle().fill(Color.white)
                    Circle()
                        .stroke(tint.color, lineWidth: max(3, size * 0.075))
                        .padding(2)
                }
            )
            .bananaShadow(BananaTheme.softShadow)
            .scaleEffect(scale)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - BananaPillButtonStyle
/// Wide pill button used for the "big chunky" CTAs (Open Settings, Restore, etc.).
struct BananaPillButtonStyle: ButtonStyle {
    enum Variant {
        case primary    // pink → purple
        case secondary  // cream w/ pink border
        case destructive // red

        var background: AnyShapeStyle {
            switch self {
            case .primary:     return AnyShapeStyle(BananaTheme.pinkPurple)
            case .secondary:   return AnyShapeStyle(Color.white)
            case .destructive: return AnyShapeStyle(Color.bannerRed)
            }
        }

        var foreground: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary:             return .partyPink
            }
        }

        var border: Color? {
            switch self {
            case .secondary: return .partyPink
            default:         return nil
            }
        }
    }

    var variant: Variant = .primary

    func makeBody(configuration: Configuration) -> some View {
        let scale = configuration.isPressed ? 0.96 : 1.0
        return configuration.label
            .font(BananaTheme.heading(18))
            .foregroundStyle(variant.foreground)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(variant.background)
            )
            .overlay(
                Group {
                    if let border = variant.border {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(border, lineWidth: 3)
                    }
                }
            )
            .bananaShadow(BananaTheme.softShadow)
            .scaleEffect(scale)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - BananaChipButtonStyle
/// Small icon+label "chip" used in toolbars (filter, stickers, undo, etc.).
struct BananaChipButtonStyle: ButtonStyle {
    var tint: BananaCircleButtonStyle.Tint = .pink
    var filled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let bgFill = filled ? AnyShapeStyle(tint.color) : AnyShapeStyle(Color.white.opacity(0.95))
        let fg     = filled ? Color.white : tint.color
        let scale  = configuration.isPressed ? 0.93 : 1.0
        return configuration.label
            .font(BananaTheme.caption(13))
            .foregroundStyle(fg)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous).fill(bgFill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.color, lineWidth: filled ? 0 : 2)
            )
            .bananaShadow(BananaTheme.softShadow)
            .scaleEffect(scale)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
