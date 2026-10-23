import SwiftUI

/// A recipe's picture: its hand-drawn glass icon from the Figma glassware library on a soft paper gradient, or
/// for a bartender drink, its own colors. Photos come back after Garrett's shoot.
struct RecipeArt: View {
    let recipe: Recipe
    var iconScale: CGFloat = 0.4

    var body: some View {
        if recipe.isInvented {
            InventedArt(colors: recipe.colors ?? [], glass: recipe.glass, iconScale: iconScale)
                .accessibilityHidden(true)
        } else {
            GlassArt(glasses: [recipe.glass], iconScale: iconScale)
                .accessibilityHidden(true)
        }
    }
}

/// One or more glass icons side by side on the paper gradient.
struct GlassArt: View {
    let glasses: [String]
    var iconScale: CGFloat = 0.4

    var body: some View {
        LinearGradient(
            colors: [Color(red: 250 / 255, green: 250 / 255, blue: 249 / 255),
                     Color(red: 236 / 255, green: 235 / 255, blue: 232 / 255)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay {
            GeometryReader { geo in
                let side = min(geo.size.width * iconScale, geo.size.height * 0.7)
                HStack(spacing: side * 0.35) {
                    ForEach(Array(glasses.enumerated()), id: \.offset) { _, glass in
                        GlassIcon(catalogGlass: glass)
                            .foregroundStyle(Color.ink)
                            .frame(width: side, height: side)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// A bartender drink's artwork: a gradient poured from its own ingredients, under a white glass icon.
/// The one place Swizzle uses color, by Garrett's rule.
private struct InventedArt: View {
    let colors: [String]
    let glass: String
    let iconScale: CGFloat

    var body: some View {
        var palette = colors.compactMap { UInt32($0.dropFirst(), radix: 16) }.map { Color(hex: $0) }
        if palette.count < 2 { palette += [Color(hex: 0xF2E6C9), Color(hex: 0xD9C1E8)] }
        let first = palette[0], last = palette[palette.count - 1]
        return GeometryReader { geo in
            let side = min(geo.size.width * iconScale, geo.size.height * 0.7)
            let reach = max(geo.size.width, geo.size.height)
            ZStack {
                LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [first, first.opacity(0)], center: UnitPoint(x: 0.18, y: 0.18), startRadius: 0, endRadius: reach * 0.6)
                RadialGradient(colors: [last, last.opacity(0)], center: UnitPoint(x: 0.9, y: 0.9), startRadius: 0, endRadius: reach * 0.6)
                RadialGradient(colors: [.white.opacity(0.35), .white.opacity(0)], center: UnitPoint(x: 0.3, y: 0), startRadius: 0, endRadius: reach * 0.7)
                GlassIcon(catalogGlass: glass)
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(width: side, height: side)
                    .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
            }
        }
    }
}

/// The bookmark on every recipe card, row, pick and detail page. Glass when empty, black when saved,
/// matching the Figma "Bookmark button" component.
struct BookmarkButton: View {
    @Environment(AppStore.self) private var store
    let recipe: Recipe
    var size: CGFloat = 32

    var body: some View {
        let on = store.isSaved(recipe.id)
        Button {
            withAnimation(.snappy) { store.toggleSaved(recipe) }
        } label: {
            Image(systemName: on ? "bookmark.fill" : "bookmark")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(on ? Color.paper : Color.ink)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(BookmarkBackground(saved: on))
        .accessibilityLabel(on ? "Remove \(recipe.name) from saved" : "Save \(recipe.name)")
    }
}

private struct BookmarkBackground: ViewModifier {
    let saved: Bool

    func body(content: Content) -> some View {
        if saved {
            content.background(Circle().fill(Color.ink))
        } else {
            content.glassEffect(.regular.interactive(), in: .circle)
        }
    }
}
