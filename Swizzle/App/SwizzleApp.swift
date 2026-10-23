import SwiftUI
import UIKit

@main
struct SwizzleApp: App {
    @State private var store = AppStore()

    init() {
        // Tab bar labels in Helvetica Neue, like the rest of the interface.
        let font = UIFont(name: "HelveticaNeue", size: 11) ?? .systemFont(ofSize: 11)
        UITabBarItem.appearance().setTitleTextAttributes([.font: font], for: .normal)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
