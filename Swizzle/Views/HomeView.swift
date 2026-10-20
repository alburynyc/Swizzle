import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let can = store.canMake.count, away = store.oneAway.count
        let list = store.filtered
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(store.name.isEmpty ? "Welcome back" : "Welcome back, \(store.name)")
                    .font(SwizzleFont.display(32, relativeTo: .largeTitle))
                    .gutter()

                Button {
                    store.focusSearch = true
                    store.tab = .search
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Color.ink)
                        Text("What’ll it be today?")
                            .font(SwizzleFont.ui(17))
                            .foregroundStyle(Color.ink3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "mic").foregroundStyle(Color.ink)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
                .padding(.top, 20)
                .gutter()

                SectionLabel(text: "Today’s picks")
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        PickCard(recipe: store.todaysPick, who: "For You")
                        if let pick = store.editorsPick {
                            PickCard(recipe: pick, who: "Editor’s Picks")
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 16, for: .scrollContent)

                SectionLabel(text: "Explore cocktail recipes")
                ScrollView(.horizontal) {
                    HStack(spacing: 18) {
                        FilterTab(title: "All", count: nil, filter: .all)
                        FilterTab(title: "Can make now", count: can, filter: .can)
                        FilterTab(title: "One bottle away", count: away, filter: .away)
                    }
                }
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .padding(.bottom, 18)

                Group {
                    if list.isEmpty {
                        if store.filter == .can {
                            VStack(spacing: 0) {
                                EmptyNote(title: "Nothing yet", message: "Add a few bottles to your library and the drinks you can make show up here.")
                                Button("Add bottles") { store.tab = .library }
                                    .buttonStyle(InkButtonStyle(height: 46))
                                    .frame(width: 180)
                            }
                        } else {
                            EmptyNote(title: "All clear", message: "No drinks are exactly one bottle away right now.")
                        }
                    } else {
                        RecipeGrid(recipes: list)
                    }
                }
                .gutter()
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color.paper)
    }
}

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(SwizzleFont.ui(14))
            .padding(.top, 32)
            .padding(.bottom, 16)
            .gutter()
    }
}

/// "All · Can make now · One bottle away", underlined when selected.
private struct FilterTab: View {
    @Environment(AppStore.self) private var store
    let title: String
    let count: Int?
    let filter: HomeFilter

    var body: some View {
        let on = store.filter == filter
        Button {
            withAnimation(.snappy) { store.setFilter(filter) }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(title).font(SwizzleFont.ui(20))
                if let count {
                    Text("\(count)")
                        .font(SwizzleFont.ui(12))
                        .monospacedDigit()
                        .baselineOffset(8)
                }
            }
            .foregroundStyle(on ? Color.ink : Color.ink3)
            .padding(.bottom, 3)
            .overlay(alignment: .bottom) {
                Rectangle().fill(on ? Color.ink : .clear).frame(height: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
