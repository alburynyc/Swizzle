import SwiftUI

/// The cocktail icons from the Figma board "Glassware — Cocktail icon library" (64 × 64 artboards,
/// drawn as 2 pt strokes). Every recipe shows the icon for its glass. There is no mug icon yet, so
/// mugs use Highball, as in the Figma file.
enum GlassType: String, CaseIterable {
    case martini, rocks, wine, coupe, collins, flute, margarita, nicknora, hurricane, snifter, highball, cordial

    init(catalogGlass: String) {
        self = GlassType(rawValue: catalogGlass) ?? (catalogGlass == "mug" ? .highball : .rocks)
    }
}

struct GlassIcon: Shape {
    let glass: GlassType

    init(_ glass: GlassType) { self.glass = glass }
    init(catalogGlass: String) { glass = GlassType(catalogGlass: catalogGlass) }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        Self.draw(glass, into: &p)
        let s = min(rect.width, rect.height) / 64
        let transform = CGAffineTransform(translationX: rect.midX - 32 * s, y: rect.midY - 32 * s).scaledBy(x: s, y: s)
        return p.applying(transform)
    }

    // Generated from the board's SVG export; edit the board, not these numbers.
    private static func draw(_ glass: GlassType, into p: inout Path) {
        switch glass {
        case .martini:
            p.move(to: CGPoint(x: 10.67, y: 13.33))
            p.addLine(to: CGPoint(x: 53.33, y: 13.33))
            p.addLine(to: CGPoint(x: 32, y: 37.33))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 37.33))
            p.addLine(to: CGPoint(x: 32, y: 53.33))
            p.move(to: CGPoint(x: 21.33, y: 53.33))
            p.addLine(to: CGPoint(x: 42.67, y: 53.33))
            p.move(to: CGPoint(x: 17.33, y: 20))
            p.addLine(to: CGPoint(x: 46.67, y: 20))
        case .rocks:
            p.move(to: CGPoint(x: 14.67, y: 17.33))
            p.addLine(to: CGPoint(x: 49.33, y: 17.33))
            p.addLine(to: CGPoint(x: 46.67, y: 52))
            p.addLine(to: CGPoint(x: 17.33, y: 52))
            p.closeSubpath()
            p.move(to: CGPoint(x: 16, y: 34.67))
            p.addLine(to: CGPoint(x: 48, y: 34.67))
            p.move(to: CGPoint(x: 24, y: 28))
            p.addLine(to: CGPoint(x: 26.67, y: 22.67))
            p.addLine(to: CGPoint(x: 36, y: 26.67))
            p.addLine(to: CGPoint(x: 33.33, y: 34.67))
            p.move(to: CGPoint(x: 22.67, y: 46.67))
            p.addLine(to: CGPoint(x: 41.33, y: 46.67))
        case .wine:
            p.move(to: CGPoint(x: 20, y: 10.67))
            p.addLine(to: CGPoint(x: 44, y: 10.67))
            p.addCurve(to: CGPoint(x: 46.67, y: 29.33), control1: CGPoint(x: 45.33, y: 17.33), control2: CGPoint(x: 48, y: 22.67))
            p.addCurve(to: CGPoint(x: 32, y: 41.33), control1: CGPoint(x: 45.33, y: 37.33), control2: CGPoint(x: 40, y: 41.33))
            p.addCurve(to: CGPoint(x: 17.33, y: 29.33), control1: CGPoint(x: 24, y: 41.33), control2: CGPoint(x: 18.67, y: 37.33))
            p.addCurve(to: CGPoint(x: 20, y: 10.67), control1: CGPoint(x: 16, y: 22.67), control2: CGPoint(x: 18.67, y: 17.33))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 41.33))
            p.addLine(to: CGPoint(x: 32, y: 54.67))
            p.move(to: CGPoint(x: 22.67, y: 54.67))
            p.addLine(to: CGPoint(x: 41.33, y: 54.67))
            p.move(to: CGPoint(x: 17.33, y: 26.67))
            p.addCurve(to: CGPoint(x: 46.67, y: 26.67), control1: CGPoint(x: 26.67, y: 24), control2: CGPoint(x: 37.33, y: 29.33))
        case .coupe:
            p.move(to: CGPoint(x: 12, y: 17.33))
            p.addLine(to: CGPoint(x: 52, y: 17.33))
            p.addCurve(to: CGPoint(x: 32, y: 37.33), control1: CGPoint(x: 52, y: 29.33), control2: CGPoint(x: 44, y: 37.33))
            p.addCurve(to: CGPoint(x: 12, y: 17.33), control1: CGPoint(x: 20, y: 37.33), control2: CGPoint(x: 12, y: 29.33))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 37.33))
            p.addLine(to: CGPoint(x: 32, y: 53.33))
            p.move(to: CGPoint(x: 21.33, y: 53.33))
            p.addLine(to: CGPoint(x: 42.67, y: 53.33))
            p.move(to: CGPoint(x: 13.33, y: 24))
            p.addLine(to: CGPoint(x: 50.67, y: 24))
        case .collins:
            p.move(to: CGPoint(x: 21.33, y: 10.67))
            p.addLine(to: CGPoint(x: 42.67, y: 10.67))
            p.addLine(to: CGPoint(x: 41.33, y: 53.33))
            p.addLine(to: CGPoint(x: 22.67, y: 53.33))
            p.closeSubpath()
            p.move(to: CGPoint(x: 22, y: 29.33))
            p.addLine(to: CGPoint(x: 42, y: 29.33))
            p.move(to: CGPoint(x: 29.33, y: 34.67))
            p.addLine(to: CGPoint(x: 36, y: 34.67))
            p.addLine(to: CGPoint(x: 36, y: 42.67))
            p.addLine(to: CGPoint(x: 29.33, y: 42.67))
            p.closeSubpath()
            p.move(to: CGPoint(x: 26.67, y: 48))
            p.addLine(to: CGPoint(x: 37.33, y: 48))
        case .flute:
            p.move(to: CGPoint(x: 24, y: 9.33))
            p.addLine(to: CGPoint(x: 40, y: 9.33))
            p.addLine(to: CGPoint(x: 38.67, y: 30.67))
            p.addCurve(to: CGPoint(x: 32, y: 40), control1: CGPoint(x: 38, y: 37.33), control2: CGPoint(x: 36, y: 40))
            p.addCurve(to: CGPoint(x: 25.33, y: 30.67), control1: CGPoint(x: 28, y: 40), control2: CGPoint(x: 26, y: 37.33))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 40))
            p.addLine(to: CGPoint(x: 32, y: 54.67))
            p.move(to: CGPoint(x: 24, y: 54.67))
            p.addLine(to: CGPoint(x: 40, y: 54.67))
            p.move(to: CGPoint(x: 24.93, y: 22.67))
            p.addLine(to: CGPoint(x: 39.07, y: 22.67))
        case .margarita:
            p.move(to: CGPoint(x: 9.33, y: 14.67))
            p.addLine(to: CGPoint(x: 54.67, y: 14.67))
            p.addCurve(to: CGPoint(x: 40, y: 28), control1: CGPoint(x: 52, y: 22.67), control2: CGPoint(x: 48, y: 26.67))
            p.addCurve(to: CGPoint(x: 32, y: 37.33), control1: CGPoint(x: 38.67, y: 34.67), control2: CGPoint(x: 36, y: 37.33))
            p.addCurve(to: CGPoint(x: 24, y: 28), control1: CGPoint(x: 28, y: 37.33), control2: CGPoint(x: 25.33, y: 34.67))
            p.addCurve(to: CGPoint(x: 9.33, y: 14.67), control1: CGPoint(x: 16, y: 26.67), control2: CGPoint(x: 12, y: 22.67))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 37.33))
            p.addLine(to: CGPoint(x: 32, y: 53.33))
            p.move(to: CGPoint(x: 21.33, y: 53.33))
            p.addLine(to: CGPoint(x: 42.67, y: 53.33))
            p.move(to: CGPoint(x: 13.33, y: 21.33))
            p.addLine(to: CGPoint(x: 50.67, y: 21.33))
        case .nicknora:
            p.move(to: CGPoint(x: 18.67, y: 14.67))
            p.addLine(to: CGPoint(x: 45.33, y: 14.67))
            p.addCurve(to: CGPoint(x: 32, y: 37.33), control1: CGPoint(x: 45.33, y: 26.67), control2: CGPoint(x: 41.33, y: 36))
            p.addCurve(to: CGPoint(x: 18.67, y: 14.67), control1: CGPoint(x: 22.67, y: 36), control2: CGPoint(x: 18.67, y: 26.67))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 37.33))
            p.addLine(to: CGPoint(x: 32, y: 53.33))
            p.move(to: CGPoint(x: 22.67, y: 53.33))
            p.addLine(to: CGPoint(x: 41.33, y: 53.33))
            p.move(to: CGPoint(x: 19.6, y: 22.67))
            p.addLine(to: CGPoint(x: 44.4, y: 22.67))
        case .hurricane:
            p.move(to: CGPoint(x: 21.33, y: 10.67))
            p.addLine(to: CGPoint(x: 42.67, y: 10.67))
            p.addCurve(to: CGPoint(x: 44, y: 32), control1: CGPoint(x: 38.67, y: 18.67), control2: CGPoint(x: 38.67, y: 24))
            p.addCurve(to: CGPoint(x: 32, y: 48), control1: CGPoint(x: 50.67, y: 44), control2: CGPoint(x: 42.67, y: 48))
            p.addCurve(to: CGPoint(x: 20, y: 32), control1: CGPoint(x: 21.33, y: 48), control2: CGPoint(x: 13.33, y: 44))
            p.addCurve(to: CGPoint(x: 21.33, y: 10.67), control1: CGPoint(x: 25.33, y: 24), control2: CGPoint(x: 25.33, y: 18.67))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 48))
            p.addLine(to: CGPoint(x: 32, y: 54.67))
            p.move(to: CGPoint(x: 22.67, y: 54.67))
            p.addLine(to: CGPoint(x: 41.33, y: 54.67))
            p.move(to: CGPoint(x: 22.67, y: 26.67))
            p.addLine(to: CGPoint(x: 41.33, y: 26.67))
        case .snifter:
            p.move(to: CGPoint(x: 22.67, y: 13.33))
            p.addLine(to: CGPoint(x: 41.33, y: 13.33))
            p.addCurve(to: CGPoint(x: 49.33, y: 33.33), control1: CGPoint(x: 42.67, y: 20), control2: CGPoint(x: 49.33, y: 26.67))
            p.addCurve(to: CGPoint(x: 32, y: 46.67), control1: CGPoint(x: 49.33, y: 42.67), control2: CGPoint(x: 41.33, y: 46.67))
            p.addCurve(to: CGPoint(x: 14.67, y: 33.33), control1: CGPoint(x: 22.67, y: 46.67), control2: CGPoint(x: 14.67, y: 42.67))
            p.addCurve(to: CGPoint(x: 22.67, y: 13.33), control1: CGPoint(x: 14.67, y: 26.67), control2: CGPoint(x: 21.33, y: 20))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 46.67))
            p.addLine(to: CGPoint(x: 32, y: 54.67))
            p.move(to: CGPoint(x: 22.67, y: 54.67))
            p.addLine(to: CGPoint(x: 41.33, y: 54.67))
            p.move(to: CGPoint(x: 16, y: 33.33))
            p.addCurve(to: CGPoint(x: 48, y: 33.33), control1: CGPoint(x: 26.67, y: 30.67), control2: CGPoint(x: 37.33, y: 36))
        case .highball:
            p.move(to: CGPoint(x: 16, y: 14.67))
            p.addLine(to: CGPoint(x: 48, y: 14.67))
            p.addLine(to: CGPoint(x: 45.33, y: 53.33))
            p.addLine(to: CGPoint(x: 18.67, y: 53.33))
            p.closeSubpath()
            p.move(to: CGPoint(x: 17.33, y: 32))
            p.addLine(to: CGPoint(x: 46.67, y: 32))
            p.move(to: CGPoint(x: 26.67, y: 24))
            p.addLine(to: CGPoint(x: 34.67, y: 22.67))
            p.addLine(to: CGPoint(x: 37.33, y: 30.67))
            p.move(to: CGPoint(x: 24, y: 46.67))
            p.addLine(to: CGPoint(x: 40, y: 46.67))
        case .cordial:
            p.move(to: CGPoint(x: 24, y: 14.67))
            p.addLine(to: CGPoint(x: 40, y: 14.67))
            p.addLine(to: CGPoint(x: 38.67, y: 29.33))
            p.addCurve(to: CGPoint(x: 32, y: 37.33), control1: CGPoint(x: 38, y: 34.67), control2: CGPoint(x: 36, y: 37.33))
            p.addCurve(to: CGPoint(x: 25.33, y: 29.33), control1: CGPoint(x: 28, y: 37.33), control2: CGPoint(x: 26, y: 34.67))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 37.33))
            p.addLine(to: CGPoint(x: 32, y: 53.33))
            p.move(to: CGPoint(x: 24, y: 53.33))
            p.addLine(to: CGPoint(x: 40, y: 53.33))
            p.move(to: CGPoint(x: 24.8, y: 24))
            p.addLine(to: CGPoint(x: 39.2, y: 24))
        }
    }
}
