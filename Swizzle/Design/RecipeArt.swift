import SwiftUI

/// The few drinks with real photography so far. Every other drink shows its glass icon until the shoot.
enum RecipePhoto {
    static func name(for recipeID: String) -> String? {
        switch recipeID {
        case "negroni": "Photo-negroni"
        case "oldfashioned": "Photo-oldfashioned"
        case "martini": "Photo-martini"
        default: nil
        }
    }
}

/// A recipe's picture: its photo when there is one, otherwise its glass icon on a soft paper gradient.
struct RecipeArt: View {
    let recipe: Recipe
    var iconScale: CGFloat = 0.4
    var lineWidth: CGFloat = 1.6

    var body: some View {
        if let photo = RecipePhoto.name(for: recipe.id) {
            Color.field
                .overlay {
                    Image(photo)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .accessibilityHidden(true)
        } else {
            LinearGradient(
                colors: [Color(red: 250 / 255, green: 250 / 255, blue: 249 / 255),
                         Color(red: 236 / 255, green: 235 / 255, blue: 232 / 255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .overlay {
                GeometryReader { geo in
                    let side = min(geo.size.width * iconScale, geo.size.height * 0.7)
                    GlassIcon(catalogGlass: recipe.glass)
                        .stroke(Color.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .frame(width: side, height: side)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)
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
        .sensoryFeedback(.selection, trigger: on)
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
