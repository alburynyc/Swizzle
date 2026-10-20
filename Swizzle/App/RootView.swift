import SwiftUI
import PhotosUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            if store.onboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: store.onboarded)
        .font(SwizzleFont.ui(15))
        .foregroundStyle(Color.ink)
        .tint(Color.ink)
        .background(Color.paper)
        .modifier(BarScanning())
        .overlay(alignment: .bottom) { ToastView() }
    }
}

struct MainTabView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.tab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                RecipeStack { HomeView() }
            }
            Tab("For You", systemImage: "sparkle", value: AppTab.forYou) {
                RecipeStack { ForYouView() }
            }
            Tab("Library", image: "TabLibrary", value: AppTab.library) {
                RecipeStack { LibraryView() }
            }
            .badge(store.bar.count)
            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                RecipeStack { SearchView() }
            }
        }
    }
}

/// A tab's navigation stack: the screen itself with no bar, pushing recipe pages.
struct RecipeStack<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            content
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
        }
    }
}

/// Camera, photo library, scan review and manual-add sheets, shared by onboarding and the Library.
private struct BarScanning: ViewModifier {
    @Environment(AppStore.self) private var store
    @State private var pickerItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        @Bindable var store = store
        content
            .fullScreenCover(isPresented: $store.showCamera) {
                CameraPicker { image in
                    Task { await store.scan(image) }
                } onClose: {
                    store.showCamera = false
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $store.showPhotoPicker, selection: $pickerItem, matching: .images)
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                pickerItem = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        await store.scan(image)
                    } else {
                        store.show("That photo couldn't be opened. Try another one.")
                    }
                }
            }
            .sheet(isPresented: $store.showScanReview) {
                ScanReviewSheet()
            }
            .sheet(isPresented: $store.showManualAdd) {
                ManualAddSheet()
            }
    }
}

/// A short glass message near the bottom of the screen.
struct ToastView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if let message = store.toast {
            Text(message)
                .font(SwizzleFont.ui(13))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, 16)
                .padding(.bottom, 96)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: message) {
                    do {
                        try await Task.sleep(for: .seconds(2.6))
                        withAnimation(.snappy) { store.toast = nil }
                    } catch {
                        // A newer message replaced this one; it clears itself.
                    }
                }
                .allowsHitTesting(false)
        }
    }
}
