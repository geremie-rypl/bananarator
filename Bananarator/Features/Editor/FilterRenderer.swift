import SwiftUI
import UIKit

enum ProceduralFilterKind: String, CaseIterable {
    case softGlow
    case vintageVibes
    case neonDreams
    case goldenHour

    init?(filterId: String) {
        switch filterId {
        case "filter.basic.glow": self = .softGlow
        case "filter.basic.vintage": self = .vintageVibes
        case "filter.basic.neon": self = .neonDreams
        case "secret.filter.golden": self = .goldenHour
        default: return nil
        }
    }
}

struct ProceduralFilterOverlay: View {
    let kind: ProceduralFilterKind

    var body: some View {
        switch kind {
        case .softGlow:
            GeometryReader { geo in
                RadialGradient(
                    colors: [Color.white.opacity(0.55), Color.white.opacity(0.0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.7
                )
            }
            .blendMode(.screen)

        case .vintageVibes:
            ZStack {
                Color(red: 0.55, green: 0.38, blue: 0.20)
                    .opacity(0.28)
                    .blendMode(.multiply)
                GeometryReader { geo in
                    RadialGradient(
                        colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                        center: .center,
                        startRadius: min(geo.size.width, geo.size.height) * 0.35,
                        endRadius: max(geo.size.width, geo.size.height) * 0.85
                    )
                }
                .blendMode(.multiply)
            }

        case .neonDreams:
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.30, blue: 0.55).opacity(0.45),
                    Color(red: 0.10, green: 0.85, blue: 1.00).opacity(0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.screen)

        case .goldenHour:
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.78, blue: 0.32).opacity(0.55),
                    Color(red: 1.00, green: 0.52, blue: 0.20).opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.screen)
        }
    }
}

enum FilterRenderer {
    /// Returns the overlay image for a filter at the given size. Procedural
    /// filters are rasterized here so the existing composite pipeline in
    /// ExportService.createExportImages works unchanged.
    static func overlayImage(for filter: FilterItem, size: CGSize) -> UIImage? {
        if let kind = ProceduralFilterKind(filterId: filter.id) {
            return rasterize(kind: kind, size: size)
        }
        return UIImage(named: filter.imageName)
    }

    private static func rasterize(kind: ProceduralFilterKind, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            draw(kind: kind, in: ctx.cgContext, size: size)
        }
    }

    private static func draw(kind: ProceduralFilterKind, in ctx: CGContext, size: CGSize) {
        let space = CGColorSpaceCreateDeviceRGB()
        let rect = CGRect(origin: .zero, size: size)

        switch kind {
        case .softGlow:
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [
                UIColor(white: 1, alpha: 0.55).cgColor,
                UIColor(white: 1, alpha: 0.00).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
            ctx.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: max(size.width, size.height) * 0.7,
                options: [.drawsBeforeStartLocation]
            )

        case .vintageVibes:
            ctx.setFillColor(UIColor(red: 0.55, green: 0.38, blue: 0.20, alpha: 0.28).cgColor)
            ctx.fill(rect)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let inner = min(size.width, size.height) * 0.35
            let outer = max(size.width, size.height) * 0.85
            let colors = [
                UIColor(white: 0, alpha: 0.0).cgColor,
                UIColor(white: 0, alpha: 0.55).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
            ctx.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: inner,
                endCenter: center, endRadius: outer,
                options: []
            )

        case .neonDreams:
            let colors = [
                UIColor(red: 1.00, green: 0.30, blue: 0.55, alpha: 0.45).cgColor,
                UIColor(red: 0.10, green: 0.85, blue: 1.00, alpha: 0.45).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
            ctx.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )

        case .goldenHour:
            let colors = [
                UIColor(red: 1.00, green: 0.78, blue: 0.32, alpha: 0.55).cgColor,
                UIColor(red: 1.00, green: 0.52, blue: 0.20, alpha: 0.18).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
            ctx.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
    }
}
