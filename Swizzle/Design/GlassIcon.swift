import SwiftUI

/// The cocktail icons from the Figma board "Glassware — Hand-drawn black icon library" (node 42:225,
/// 64 × 64 artboards). Each is a `Glass-<type>` vector image in the asset catalog, set to render as a
/// template so it takes the color it's given. Every recipe shows the icon for its glass. There is no
/// mug icon yet, so mugs use Highball, as in the Figma file.
enum GlassType: String, CaseIterable {
    case martini, rocks, wine, coupe, collins, flute, margarita, nicknora, hurricane, snifter, highball, cordial

    init(catalogGlass: String) {
        self = GlassType(rawValue: catalogGlass) ?? (catalogGlass == "mug" ? .highball : .rocks)
    }
}

/// One hand-drawn glass, filled with the current foreground style.
struct GlassIcon: View {
    let glass: GlassType

    init(_ glass: GlassType) { self.glass = glass }
    init(catalogGlass: String) { glass = GlassType(catalogGlass: catalogGlass) }

    var body: some View {
        Image("Glass-\(glass.rawValue)")
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
    }
}
