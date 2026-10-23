import SwiftUI

struct ForYouView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let saved = store.savedRecipes
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(eyebrow: "Made for your bar", title: "For you")
                AskTheBartenderCard()
                if !store.invented.isEmpty {
                    SubHeader(title: "Invented for you", trailing: "\(store.invented.count)")
                    RecipeGrid(recipes: store.invented)
                }
                SubHeader(title: "Saved", trailing: "\(saved.count)")
                if saved.isEmpty {
                    EmptyNote(message: "Tap the bookmark on any drink to keep it here.")
                        .padding(.top, -24)
                } else {
                    RecipeGrid(recipes: saved)
                }
            }
            .gutter()
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color.paper)
    }
}

/// "Ask the bartender" invents three drinks from the person's bottles (see `Bartender`); free accounts
/// get a few asks a day. Its drifting color is the one place Swizzle allows color, by Garrett's rule
/// for bartender drinks.
private struct AskTheBartenderCard: View {
    @Environment(AppStore.self) private var store
    @State private var drift = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let unavailable = Bartender.unavailableReason
        let left = store.freeAsksLeft.map { $0 == 0 ? " · No free asks left today" : " · \($0) free today" } ?? ""
        let subtitle = store.inventing ? "Inventing three drinks from what’s on your shelf"
            : unavailable ?? (store.bar.isEmpty ? "Add bottles to your library first"
                              : "Three new drinks from your \(store.haveKeys.count) bottles" + left)
        Button {
            Task { await store.askTheBartender() }
        } label: {
            card(subtitle: subtitle)
        }
        .buttonStyle(.plain)
        .disabled(store.inventing || unavailable != nil)
        .onAppear {
            store.bartender.prewarm()
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private func card(subtitle: String) -> some View {
        ZStack(alignment: .bottom) {
            ZStack {
                LinearGradient(colors: [Color(hex: 0xF4ECE4), Color(hex: 0xECE9EF), Color(hex: 0xE7EEE9)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                blob(0xF1B9A0, x: drift ? 0.38 : 0.2, y: drift ? 0.5 : 0.3)
                blob(0xC9BDE6, x: drift ? 0.55 : 0.8, y: drift ? 0.45 : 0.25)
                blob(0xF3D79A, x: drift ? 0.6 : 0.45, y: drift ? 0.55 : 0.85)
                blob(0xB5DCCD, x: drift ? 0.85 : 0.7, y: drift ? 0.9 : 0.7)
            }
            .blur(radius: 30)
            .clipped()

            HStack(spacing: 12) {
                if store.inventing {
                    ProgressView().tint(Color.ink)
                } else {
                    Image(systemName: "sparkle")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.inventing ? "Shaking up ideas…" : "Ask the bartender")
                        .font(SwizzleFont.ui(15, weight: .medium))
                    Text(subtitle)
                        .font(SwizzleFont.ui(12))
                        .foregroundStyle(Color.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .padding(12)
        }
        .aspectRatio(370 / 170, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func blob(_ hex: UInt32, x: CGFloat, y: CGFloat) -> some View {
        GeometryReader { geo in
            Circle()
                .fill(RadialGradient(colors: [Color(hex: hex), Color(hex: hex).opacity(0)], center: .center, startRadius: 0, endRadius: geo.size.width * 0.3))
                .frame(width: geo.size.width * 0.62, height: geo.size.width * 0.62)
                .position(x: geo.size.width * x, y: geo.size.height * y)
                .opacity(0.75)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
