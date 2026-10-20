import SwiftUI

struct SearchView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "Search")
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                    TextField("Drink, bottle or ingredient", text: $query)
                        .font(SwizzleFont.ui(17))
                        .focused($focused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Color.ink3) }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .glassEffect(.regular.interactive(), in: .capsule)

                results
            }
            .gutter()
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.paper)
        .onAppear {
            if store.focusSearch {
                focused = true
                store.focusSearch = false
            }
        }
    }

    @ViewBuilder private var results: some View {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty {
            SmallCaps(text: "Browse by spirit")
                .padding(.top, 22)
                .padding(.bottom, 8)
            FlowLayout {
                ForEach(store.catalog.bottles(in: "Spirits")) { bottle in
                    ChipButton(title: bottle.name, isOn: false) { query = bottle.name }
                }
            }
        } else {
            let found = matches(q)
            if found.isEmpty {
                EmptyNote(title: "No match", message: "Nothing called “\(q)”. Try a spirit, like gin or tequila.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(found) { RecipeRow(recipe: $0) }
                }
                .padding(.top, 18)
            }
        }
    }

    /// Drinks whose name or ingredients mention the query, or that use a bottle the query names.
    private func matches(_ q: String) -> [Recipe] {
        let lower = q.lowercased()
        let keys = Set(store.catalog.guesses(for: q).map(\.key))
        return store.catalog.recipes.filter { r in
            r.name.lowercased().contains(lower)
                || r.ing.contains { i in i.item.lowercased().contains(lower) || (i.bottle.map { keys.contains($0) } ?? false) }
        }
    }
}
