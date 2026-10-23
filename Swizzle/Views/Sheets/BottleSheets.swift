import SwiftUI

/// "What's on your shelf?": every catalog bottle as a chip.
struct ManualAddSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SheetTitle(title: "What’s on your shelf?",
                               message: "\(store.bar.count) bottle\(store.bar.count == 1 ? "" : "s") on your shelf")
                    BottleChips()
                }
                .gutter()
                .padding(.vertical, 22)
            }
            .safeAreaInset(edge: .bottom) {
                Button("Done") { dismiss() }
                    .buttonStyle(InkButtonStyle(height: 50))
                    .gutter()
                    .padding(.bottom, 8)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
    }
}

/// The bottles a label scan found. Untick wrong ones, or tap one to correct it.
struct ScanReviewSheet: View {
    @Environment(AppStore.self) private var store
    @State private var correcting: DetectedBottle?

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if store.detected.isEmpty {
                        SheetTitle(title: "No bottles found",
                                   message: "Try again closer up, with labels facing the camera and good light.")
                    } else {
                        SheetTitle(title: "Found \(store.detected.count) bottle\(store.detected.count == 1 ? "" : "s")",
                                   message: "Untick anything we got wrong. Tap a bottle to correct it.")
                        VStack(spacing: 0) {
                            Divider().overlay(Color.line)
                            ForEach($store.detected) { $bottle in
                                DetectedRow(bottle: $bottle) { correcting = bottle }
                                Divider().overlay(Color.line)
                            }
                        }
                    }
                }
                .gutter()
                .padding(.vertical, 22)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    if store.detected.isEmpty {
                        Button("Close") { store.showScanReview = false }
                            .buttonStyle(InkButtonStyle(height: 50, ghost: true))
                        Button("Retake") {
                            store.showScanReview = false
                            Task {
                                // Let the sheet finish closing before the camera opens.
                                try? await Task.sleep(for: .milliseconds(450))
                                store.openCamera()
                            }
                        }
                        .buttonStyle(InkButtonStyle(height: 50))
                    } else {
                        Button("Cancel") { store.showScanReview = false }
                            .buttonStyle(InkButtonStyle(height: 50, ghost: true))
                        Button("Add to my bar") { store.addDetected() }
                            .buttonStyle(InkButtonStyle(height: 50))
                            .disabled(!store.detected.contains(where: \.include))
                    }
                }
                .gutter()
                .padding(.bottom, 8)
                .background(Color.paper)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(item: $correcting) { bottle in
                IdentifyBottleView(label: bottle.label, startKey: bottle.key, startOther: bottle.other, scannedAs: "We read the label as") { label, key, other in
                    if let i = store.detected.firstIndex(where: { $0.id == bottle.id }) {
                        store.detected[i].label = label
                        store.detected[i].key = key
                        store.detected[i].other = other
                        store.detected[i].include = true
                    }
                    correcting = nil
                } onCancel: {
                    correcting = nil
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private struct DetectedRow: View {
    @Environment(AppStore.self) private var store
    @Binding var bottle: DetectedBottle
    let onCorrect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                bottle.include.toggle()
            } label: {
                Image(systemName: bottle.include ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.ink)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(bottle.include ? "Don’t add \(bottle.label)" : "Add \(bottle.label)")

            Button(action: onCorrect) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bottle.label).font(SwizzleFont.ui(15))
                        if let kind = store.catalog.bottle(bottle.key) {
                            SmallCaps(text: kind.name + (store.has(kind.key) ? " · already on your shelf" : ""))
                        } else if bottle.other {
                            SmallCaps(text: "Not used in recipes yet")
                        } else {
                            SmallCaps(text: "Unidentified · Tap to identify")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(Color.ink2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 11)
    }
}

/// "What is this bottle?": fix the name, then pick which catalog bottle it counts as.
struct IdentifyBottleView: View {
    @Environment(AppStore.self) private var store
    let scannedAs: String
    let originalLabel: String
    let onSave: (String, String?, Bool) -> Void
    let onCancel: () -> Void

    @State private var label: String
    @State private var key: String?
    @State private var other: Bool
    @State private var touched = false

    init(label: String, startKey: String?, startOther: Bool, scannedAs: String,
         onSave: @escaping (String, String?, Bool) -> Void, onCancel: @escaping () -> Void) {
        self.scannedAs = scannedAs
        originalLabel = label
        self.onSave = onSave
        self.onCancel = onCancel
        _label = State(initialValue: label)
        _key = State(initialValue: startKey ?? Catalog.shared.guesses(for: label).first?.key)
        _other = State(initialValue: startOther && startKey == nil)
    }

    var body: some View {
        let guesses = store.catalog.guesses(for: label)
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("What is this bottle?").font(SwizzleFont.display(30))

                HStack(spacing: 12) {
                    Image(systemName: "viewfinder")
                    VStack(alignment: .leading, spacing: 2) {
                        SmallCaps(text: scannedAs)
                        Text(originalLabel).font(SwizzleFont.ui(16))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.field, in: .rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name on the bottle").font(SwizzleFont.ui(14))
                    TextField("e.g. Cointreau", text: $label)
                        .font(SwizzleFont.ui(17))
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .frame(height: 58)
                        .background(Color.field, in: .rect(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.line))
                        .onChange(of: label) { _, new in
                            if !touched, let first = store.catalog.guesses(for: new).first {
                                key = first.key
                                other = false
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: guesses.isEmpty ? "No match yet. Keep typing, or pick from the list." : "Best matches")
                    FlowLayout {
                        ForEach(guesses, id: \.self) { g in
                            ChipButton(title: store.catalog.bottle(g.key)?.name ?? g.key, detail: g.why, isOn: key == g.key) { pick(g.key) }
                        }
                    }
                }

                SmallCaps(text: "Or choose the kind of bottle").padding(.top, 4)
                ForEach(store.catalog.groups, id: \.self) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.uppercased()).font(SwizzleFont.ui(10)).foregroundStyle(Color.ink2)
                        FlowLayout {
                            ForEach(store.catalog.bottles(in: group)) { b in
                                ChipButton(title: b.name, isOn: key == b.key) { pick(b.key) }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("NONE OF THESE").font(SwizzleFont.ui(10)).foregroundStyle(Color.ink2)
                    ChipButton(title: "Something else", isOn: other) { pick(nil) }
                }
            }
            .gutter()
            .padding(.vertical, 22)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Button("Back", action: onCancel)
                    .buttonStyle(InkButtonStyle(height: 50, ghost: true))
                Button(store.catalog.bottle(key).map { "Save as \($0.name)" } ?? "Save") {
                    onSave(String(trimmed.prefix(80)), key, other)
                }
                .buttonStyle(InkButtonStyle(height: 50))
                .disabled(trimmed.isEmpty || (key == nil && !other))
            }
            .gutter()
            .padding(.bottom, 8)
            .background(Color.paper)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private func pick(_ k: String?) {
        touched = true
        key = k
        other = k == nil
    }
}

private struct SheetTitle: View {
    let title: String
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(SwizzleFont.display(30))
            Text(message).foregroundStyle(Color.ink2)
        }
        .padding(.bottom, 14)
    }
}
