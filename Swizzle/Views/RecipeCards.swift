import SwiftUI

/// The large card in Home's "Today's picks" carousel.
struct PickCard: View {
    let recipe: Recipe
    let who: String

    var body: some View {
        NavigationLink(value: recipe) {
            RecipeArt(recipe: recipe)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        stops: [.init(color: .white.opacity(0), location: 0.04),
                                .init(color: Color(white: 214 / 255).opacity(0.72), location: 0.5),
                                .init(color: Color(white: 150 / 255).opacity(0.9), location: 1)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 78)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(who).font(SwizzleFont.ui(14))
                            VStack(alignment: .leading, spacing: 4) {
                                let spirit = recipe.baseSpirit()
                                if !spirit.isEmpty { TagView(text: spirit) }
                                TagView(text: recipe.styleTag)
                            }
                            .padding(.leading, 4)
                        }
                        Text(recipe.name)
                            .font(SwizzleFont.display(30))
                            .lineLimit(1)
                            .padding(.trailing, 44)
                    }
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .frame(width: 295, height: 230)
                .clipShape(.rect(cornerRadius: 20))
                .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            BookmarkButton(recipe: recipe, size: 30)
                .padding(.trailing, 16)
                .padding(.bottom, 14)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(who): \(recipe.name)")
    }
}

/// The two-column grid card: art, name, and what the bar still needs.
struct RecipeCard: View {
    @Environment(AppStore.self) private var store
    let recipe: Recipe

    var body: some View {
        let missing = store.missingNames(recipe.ing)
        NavigationLink(value: recipe) {
            VStack(alignment: .leading, spacing: 0) {
                RecipeArt(recipe: recipe)
                    .aspectRatio(175 / 125, contentMode: .fit)
                    .clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(SwizzleFont.display(20))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(missing.isEmpty ? "Ready to make" : "+ \(missing)")
                        .font(SwizzleFont.ui(12))
                        .foregroundStyle(Color.ink2)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 14, trailing: 10))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.paper)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.ink))
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            BookmarkButton(recipe: recipe).padding(10)
        }
    }
}

struct RecipeGrid: View {
    let recipes: [Recipe]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(recipes) { RecipeCard(recipe: $0) }
        }
    }
}

/// A search result row: square art, name, bottles, and whether the bar can make it.
struct RecipeRow: View {
    @Environment(AppStore.self) private var store
    let recipe: Recipe

    var body: some View {
        let missing = store.missingNames(recipe.ing)
        let bottles = recipe.ing.filter { $0.bottle != nil }.map(\.item).joined(separator: " · ")
        NavigationLink(value: recipe) {
            HStack(spacing: 14) {
                RecipeArt(recipe: recipe, iconScale: 0.55, lineWidth: 1.4)
                    .frame(width: 72, height: 72)
                    .clipShape(.rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text(recipe.name).font(SwizzleFont.display(20))
                    Text(bottles).font(SwizzleFont.ui(12)).foregroundStyle(Color.ink2)
                    Text((missing.isEmpty ? "Ready to make" : "Need \(missing)").uppercased())
                        .font(SwizzleFont.ui(11))
                        .tracking(0.44)
                        .foregroundStyle(missing.isEmpty ? Color.ink : Color.ink2)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 44)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            BookmarkButton(recipe: recipe)
        }
    }
}
