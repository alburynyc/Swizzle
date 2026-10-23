import SwiftUI

struct LibraryView: View {
    @Environment(AppStore.self) private var store
    @State private var identifying: BarBottle?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(eyebrow: "Your home bar", title: "Library")
                ShelfCard()

                let count = Text("\(store.canMake.count)").foregroundStyle(Color.ink).fontWeight(.medium)
                Text("Your bar makes \(count) of \(store.allRecipes.count) drinks.")
                    .font(SwizzleFont.ui(14))
                    .foregroundStyle(Color.ink2)
                    .padding(.top, 16)

                SubHeader(title: "On your shelf", trailing: "\(store.bar.count) bottle\(store.bar.count == 1 ? "" : "s")")
                if store.bar.isEmpty {
                    Text("Nothing here yet. Snap a photo or tap the bottles you have below.")
                        .font(SwizzleFont.ui(12))
                        .foregroundStyle(Color.ink2)
                } else {
                    VStack(spacing: 0) {
                        Divider().overlay(Color.line)
                        ForEach(store.sortedBar) { bottle in
                            ShelfRow(bottle: bottle) { identifying = bottle }
                            Divider().overlay(Color.line)
                        }
                    }
                }

                if !store.shopping.isEmpty {
                    ShoppingList()
                }

                SubHeader(title: "Add by hand")
                BottleChips()

                Text("Recipes assume the usual fridge and pantry things: citrus, sugar, soda, juices, mint and ice.")
                    .font(SwizzleFont.ui(12))
                    .foregroundStyle(Color.ink2)
                    .padding(.top, 18)

                HStack(spacing: 16) {
                    Button("Replay the intro") { store.replayIntro() }
                        .font(SwizzleFont.ui(12))
                        .underline()
                        .foregroundStyle(Color.ink2)
                    if store.premium {
                        Text("Premium trial active").font(SwizzleFont.ui(12)).foregroundStyle(Color.ink2)
                    }
                }
                .padding(.top, 26)
            }
            .gutter()
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color.paper)
        .sheet(item: $identifying) { bottle in
            IdentifyBottleView(label: bottle.label, startKey: bottle.key, startOther: bottle.other, scannedAs: "On your shelf as") { label, key, other in
                store.updateBottle(bottle.id, label: label, key: key, other: other)
                identifying = nil
            } onCancel: {
                identifying = nil
            }
        }
    }
}

/// "Snap your shelf" before there's a photo; "Update your shelf" with the person's own photo after.
private struct ShelfCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if let photo = store.shelfPhoto {
                HStack(spacing: 14) {
                    Color.field
                        .overlay { Image(uiImage: photo).resizable().scaledToFill() }
                        .frame(width: 138, height: 138)
                        .clipShape(.rect(cornerRadius: 14))
                        .accessibilityLabel("Your shelf")
                    VStack(alignment: .leading, spacing: 0) {
                        copy(title: "Update your shelf")
                        VStack(alignment: .leading, spacing: 8) { buttons }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    copy(title: "Snap your shelf")
                    HStack(spacing: 8) { buttons }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.field, in: .rect(cornerRadius: 20))
    }

    private func copy(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(SwizzleFont.display(24))
            Text("Line up your bottles, labels facing out. We’ll read them and add them here.")
                .font(SwizzleFont.ui(12.5))
                .foregroundStyle(Color.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder private var buttons: some View {
        Button { store.openCamera() } label: { Label("Take photo", systemImage: "camera") }
            .buttonStyle(PillButtonStyle())
        Button { store.showPhotoPicker = true } label: { Label("Upload", systemImage: "photo") }
            .buttonStyle(PillButtonStyle(ghost: true))
    }
}

private struct ShelfRow: View {
    @Environment(AppStore.self) private var store
    let bottle: BarBottle
    let onIdentify: () -> Void
    @State private var confirming = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onIdentify) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(bottle.label).font(SwizzleFont.ui(15))
                    if let kind = store.catalog.bottle(bottle.key) {
                        SmallCaps(text: kind.name)
                    } else if bottle.other {
                        SmallCaps(text: "Not used in recipes yet")
                    } else {
                        Label("Unidentified · Tap to identify", systemImage: "viewfinder")
                            .font(SwizzleFont.ui(11))
                            .textCase(.uppercase)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(bottle.label)")

            Button {
                confirming = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ink2)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(bottle.label)")
        }
        .padding(.vertical, 11)
        // iOS draws this in Liquid Glass.
        .confirmationDialog("Remove \(bottle.label)?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Add to shopping list") {
                withAnimation(.snappy) { store.moveToList(bottle) }
            }
            Button("Delete", role: .destructive) {
                withAnimation(.snappy) { store.remove(bottle) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Finished the bottle? Add it to your shopping list to buy it again.")
        }
    }
}

/// Bottles to buy: ones finished on the shelf, and ones recipes need. "Got it" puts a bottle back on the shelf.
private struct ShoppingList: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        SubHeader(title: "Shopping list", trailing: "\(store.shopping.count) bottle\(store.shopping.count == 1 ? "" : "s")")
        VStack(spacing: 0) {
            Divider().overlay(Color.line)
            ForEach(store.shopping) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(SwizzleFont.ui(15))
                        let unlocks = store.unlocks(item.key)
                        if unlocks > 0 {
                            SmallCaps(text: "Makes \(unlocks) more drink\(unlocks == 1 ? "" : "s")")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Got it") {
                        withAnimation(.snappy) { store.bought(item) }
                    }
                    .font(SwizzleFont.ui(13))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Bought \(item.name)")

                    Button {
                        withAnimation(.snappy) { store.removeFromList(item) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.ink2)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Take \(item.name) off the list")
                }
                .padding(.vertical, 11)
                Divider().overlay(Color.line)
            }
        }
        ShareLink(item: store.shoppingText) {
            Label("Share list", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(PillButtonStyle(ghost: true))
        .padding(.top, 14)
    }
}

struct SmallCaps: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(SwizzleFont.ui(11, relativeTo: .caption2))
            .tracking(0.44)
            .foregroundStyle(Color.ink2)
    }
}

/// Every catalog bottle as a chip, grouped like bottles.json. Tapping one puts it on or takes it off the shelf.
struct BottleChips: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.catalog.groups, id: \.self) { group in
                SmallCaps(text: group)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                FlowLayout {
                    ForEach(store.catalog.bottles(in: group)) { bottle in
                        ChipButton(title: bottle.name, isOn: store.has(bottle.key)) {
                            store.toggleBottle(bottle.key)
                        }
                    }
                }
            }
        }
    }
}
