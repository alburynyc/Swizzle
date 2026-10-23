import SwiftUI

struct RecipeDetailView: View {
    @Environment(AppStore.self) private var store
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var showVariation = false
    @State private var confirmingDelete = false

    var body: some View {
        let ing = showVariation ? recipe.alt?.ing ?? recipe.ing : recipe.ing
        let steps = showVariation ? recipe.alt?.steps ?? recipe.steps : recipe.steps
        let name = showVariation ? recipe.alt?.name ?? recipe.name : recipe.name
        let missing = store.missing(ing)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RecipeArt(recipe: recipe, iconScale: 0.38)
                    .aspectRatio(370 / 324, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 20))

                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Text(name)
                        .font(SwizzleFont.display(40, relativeTo: .largeTitle))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 6) {
                        let spirit = recipe.baseSpirit(ing)
                        if !spirit.isEmpty { TagView(text: spirit) }
                        TagView(text: recipe.styleTag)
                    }
                }
                .padding(.top, 18)

                SmallCaps(text: "\(recipe.glassLabel) · " + (missing.isEmpty ? "Ready to make" : "Need \(store.missingNames(ing))"))
                    .padding(.top, 10)

                if let alt = recipe.alt {
                    VersionPicker(first: recipe.name, second: alt.name, showSecond: $showVariation)
                        .padding(.top, 18)
                    if showVariation, let note = alt.note {
                        Text(note)
                            .font(SwizzleFont.ui(13))
                            .foregroundStyle(Color.ink2)
                            .padding(.top, 8)
                    }
                }

                SubHeader(title: "Ingredients")
                VStack(spacing: 0) {
                    Divider().overlay(Color.line)
                    ForEach(Array(ing.enumerated()), id: \.offset) { _, item in
                        IngredientRow(ingredient: item, missing: item.bottle.map { missing.contains($0) })
                        Divider().overlay(Color.line)
                    }
                }

                SubHeader(title: "Method")
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(String(format: "%02d", index + 1))
                                .font(SwizzleFont.display(17, italic: true))
                                .foregroundStyle(Color.ink2)
                                .frame(width: 28, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.verb)
                                    .font(SwizzleFont.ui(11, weight: .medium))
                                    .tracking(0.66)
                                    .foregroundStyle(Color.ink2)
                                Text(step.text)
                                    .font(SwizzleFont.ui(15))
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                if let source = recipe.source {
                    SourceLine(source: source, isVariation: showVariation && recipe.alt != nil)
                        .padding(.top, 24)
                } else if recipe.isInvented {
                    Text("INVENTED FOR YOUR BAR")
                        .font(SwizzleFont.ui(11))
                        .tracking(0.44)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .overlay(Capsule().strokeBorder(Color.ink))
                        .padding(.top, 20)
                }
            }
            .gutter()
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if recipe.isInvented {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete drink", systemImage: "trash") { confirmingDelete = true }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                let on = store.isSaved(recipe.id)
                Button {
                    withAnimation(.snappy) { store.toggleSaved(recipe) }
                } label: {
                    Image(systemName: on ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(on ? "Remove \(recipe.name) from saved" : "Save \(recipe.name)")
            }
        }
        .deleteDrinkDialog(recipe, isPresented: $confirmingDelete) { dismiss() }
    }
}

private struct IngredientRow: View {
    let ingredient: Ingredient
    /// Nil for pantry items, which aren't tracked.
    let missing: Bool?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(ingredient.amount)
                .font(SwizzleFont.ui(14))
                .monospacedDigit()
                .foregroundStyle(Color.ink2)
                .frame(width: 76, alignment: .leading)
            Text(ingredient.item)
                .font(SwizzleFont.ui(15))
                .frame(maxWidth: .infinity, alignment: .leading)
            if missing == true, let key = ingredient.bottle {
                ListButton(key: key)
            } else if missing == false {
                HStack(spacing: 5) {
                    Image(systemName: "circle.fill").font(.system(size: 7))
                    Text("IN YOUR BAR")
                        .font(SwizzleFont.ui(11))
                        .tracking(0.44)
                }
                .foregroundStyle(Color.ink)
                .fixedSize()
            }
        }
        .padding(.vertical, 10)
    }
}

/// On a bottle the bar is missing: puts it on the shopping list, or takes it back off.
private struct ListButton: View {
    @Environment(AppStore.self) private var store
    let key: String

    var body: some View {
        let on = store.isOnList(key)
        Button {
            withAnimation(.snappy) { on ? store.removeFromList(key: key) : store.addToList(key: key) }
        } label: {
            Label(on ? "ON YOUR LIST" : "ADD TO LIST", systemImage: on ? "checkmark" : "plus")
                .font(SwizzleFont.ui(11))
                .tracking(0.44)
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
        .fixedSize()
        .accessibilityLabel(on ? "Remove from shopping list" : "Add to shopping list")
    }
}

/// The two-version switch, e.g. Classic Negroni / Negroni Sbagliato.
private struct VersionPicker: View {
    let first: String
    let second: String
    @Binding var showSecond: Bool
    @Namespace private var selection

    var body: some View {
        HStack(spacing: 4) {
            option(first, selected: !showSecond) { showSecond = false }
            option(second, selected: showSecond) { showSecond = true }
        }
        .padding(4)
        .background(Color.field, in: .capsule)
    }

    private func option(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Text(title)
                .font(SwizzleFont.ui(13))
                .lineLimit(1)
                .foregroundStyle(selected ? Color.ink : Color.ink2)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background {
                    if selected {
                        Capsule()
                            .fill(Color.paper)
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            .matchedGeometryEffect(id: "selected", in: selection)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct SourceLine: View {
    let source: RecipeSource
    let isVariation: Bool

    var body: some View {
        let converted = source.url != nil && source.name.hasPrefix("IBA") ? " · amounts converted from ml" : ""
        let own = isVariation ? " · this variation is Swizzle’s own" : ""
        var text = AttributedString("Recipe: ")
        var name = AttributedString(source.name)
        if let link = source.url.flatMap(URL.init(string:)) {
            name.link = link
            name.foregroundColor = Color.ink
            name.underlineStyle = Text.LineStyle.single
        }
        text += name
        text += AttributedString(converted + own)
        return Text(text)
            .font(SwizzleFont.ui(12))
            .foregroundStyle(Color.ink2)
            .tint(Color.ink)
    }
}
