import SwiftUI
import UIKit
import Observation

enum AppTab: Hashable {
    case home, forYou, library, search
}

enum HomeFilter: String, Codable {
    case all, can, away
}

enum Plan: String, Codable {
    case yearly, monthly
}

/// One bottle on the person's shelf. `key` is the catalog bottle it counts as; nil when nobody has identified it yet.
struct BarBottle: Codable, Identifiable, Hashable {
    var id = UUID()
    var label: String
    var key: String?
    /// True when the person said it's none of the catalog's bottles.
    var other = false
}

/// A bottle to buy: one taken off the shelf, or one a recipe needs.
struct ShoppingItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    /// The catalog bottle, when it's one the recipes use.
    var key: String?
}

/// A bottle the label scan found, waiting for the person to confirm it.
struct DetectedBottle: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var key: String?
    var other = false
    var include = true
}

/// Everything the app remembers, plus the bar-matching rules from the prototype.
@MainActor
@Observable
final class AppStore {
    let catalog = Catalog.shared

    // Saved between launches.
    private(set) var onboarded = false
    var name = ""
    private(set) var bar: [BarBottle] = []
    private(set) var saved: [String] = []
    /// Drinks Ask the bartender invented, newest first.
    private(set) var invented: [Recipe] = []
    /// Bottles to buy, in the order they were added.
    private(set) var shopping: [ShoppingItem] = []
    var plan: Plan = .yearly
    private(set) var premium = false
    private(set) var filter: HomeFilter = .all
    private(set) var shelfPhoto: UIImage?

    // Session state.
    var tab: AppTab = .home
    var onboardingStep = 0
    var focusSearch = false
    var toast: String?

    // Scanning and bottle sheets, shared by onboarding and the Library.
    var showCamera = false
    var showPhotoPicker = false
    var showManualAdd = false
    var showScanReview = false
    var scanning = false
    var detected: [DetectedBottle] = []
    /// Bottles found in onboarding, newest first, for the viewfinder's result pill.
    var scannedInOnboarding: [DetectedBottle] = []
    var viewfinderPhoto: UIImage?

    private static let stateKey = "swizzle.v1"
    private struct Saved: Codable {
        var onboarded: Bool
        var name: String
        var bar: [BarBottle]
        var saved: [String]
        var plan: Plan
        var premium: Bool
        var filter: HomeFilter
        var invented: [Recipe]?
        var askDay: Int?
        var asksToday: Int?
        var shopping: [ShoppingItem]?
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.stateKey),
           let s = try? JSONDecoder().decode(Saved.self, from: data) {
            onboarded = s.onboarded
            name = s.name
            bar = s.bar
            saved = s.saved
            plan = s.plan
            premium = s.premium
            filter = s.filter
            invented = (s.invented ?? []).map { Bartender.checked($0, catalog: catalog) }
            askDay = s.askDay ?? 0
            asksToday = s.asksToday ?? 0
            shopping = s.shopping ?? []
        }
        shelfPhoto = UIImage(contentsOfFile: Self.shelfURL.path)
    }

    func persist() {
        let s = Saved(onboarded: onboarded, name: name, bar: bar, saved: saved, plan: plan, premium: premium, filter: filter, invented: invented,
                      askDay: askDay, asksToday: asksToday, shopping: shopping)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: Self.stateKey)
        }
    }

    // MARK: Matching

    var haveKeys: Set<String> { Set(bar.compactMap(\.key)) }

    func missing(_ ing: [Ingredient]) -> [String] {
        let have = haveKeys
        return Recipe.bottleKeys(ing).filter { !have.contains($0) }
    }

    func missingNames(_ ing: [Ingredient]) -> String {
        missing(ing).map { catalog.bottle($0)?.name ?? $0 }.joined(separator: ", ")
    }

    /// Invented drinks first, then the catalog.
    var allRecipes: [Recipe] { invented + catalog.recipes }

    func recipe(_ id: String) -> Recipe? {
        invented.first { $0.id == id } ?? catalog.recipe(id)
    }

    var canMake: [Recipe] { allRecipes.filter { missing($0.ing).isEmpty } }
    var oneAway: [Recipe] { allRecipes.filter { missing($0.ing).count == 1 } }

    var filtered: [Recipe] {
        switch filter {
        case .all: allRecipes
        case .can: canMake
        case .away: oneAway
        }
    }

    func setFilter(_ f: HomeFilter) {
        filter = f
        persist()
    }

    static let editorsPickID = "oldfashioned"

    var editorsPick: Recipe? { catalog.recipe(Self.editorsPickID) }

    /// A drink from what the bar can make (or is one bottle from), changing once a day, other than the editor's pick.
    var todaysPick: Recipe {
        let can = canMake, away = oneAway
        var pool = !can.isEmpty ? can : !away.isEmpty ? away : catalog.recipes
        if pool.count > 1 { pool.removeAll { $0.id == Self.editorsPickID } }
        let day = Int(Date().timeIntervalSince1970 / 86_400)
        return pool[day % pool.count]
    }

    // MARK: Saved recipes

    func isSaved(_ id: String) -> Bool { saved.contains(id) }

    func toggleSaved(_ recipe: Recipe) {
        Sounds.pop()
        if isSaved(recipe.id) {
            saved.removeAll { $0 == recipe.id }
            Haptics.removed()
            show("Removed from saved")
        } else {
            saved.insert(recipe.id, at: 0)
            Haptics.saved()
            show("Saved to For You")
        }
        persist()
    }

    var savedRecipes: [Recipe] { saved.compactMap { recipe($0) } }

    // MARK: Bar

    func has(_ key: String) -> Bool { haveKeys.contains(key) }

    func toggleBottle(_ key: String) {
        if has(key) {
            bar.removeAll { $0.key == key }
        } else if let b = catalog.bottle(key) {
            bar.append(BarBottle(label: b.name, key: key))
        }
        persist()
    }

    func remove(_ bottle: BarBottle) {
        bar.removeAll { $0.id == bottle.id }
        persist()
    }

    func updateBottle(_ id: UUID, label: String, key: String?, other: Bool) {
        guard let i = bar.firstIndex(where: { $0.id == id }) else { return }
        let before = canMake.count
        bar[i].label = label
        bar[i].key = key
        bar[i].other = other
        persist()
        let gained = canMake.count - before
        if let b = catalog.bottle(key) {
            show("\(label) saved as \(b.name)" + (gained > 0 ? " · +\(gained) drinks" : ""))
        } else {
            show("\(label) saved")
        }
    }

    var sortedBar: [BarBottle] {
        let order = catalog.groups + ["Other"]
        func rank(_ b: BarBottle) -> Int { order.firstIndex(of: catalog.bottle(b.key)?.group ?? "Other") ?? order.count }
        return bar.enumerated().sorted { a, b in
            let ra = rank(a.element), rb = rank(b.element)
            return ra == rb ? a.offset < b.offset : ra < rb
        }.map(\.element)
    }

    // MARK: Label scan

    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            show("There's no camera here. Try Upload instead.")
        }
    }

    func scan(_ image: UIImage) async {
        keepShelf(image)
        if !onboarded { viewfinderPhoto = image }
        scanning = true
        defer { scanning = false }
        do {
            let lines = try await LabelScanner.recognizeText(in: image)
            detected = LabelScanner.bottles(in: lines, catalog: catalog)
            Haptics.scanned()
            showScanReview = true
        } catch {
            Haptics.failed()
            show("That photo couldn't be read. Try another one.")
        }
    }

    func addDetected() {
        let add = detected.filter(\.include)
        let before = canMake.count
        for d in add where !bar.contains(where: { $0.label.lowercased() == d.label.lowercased() }) {
            bar.append(BarBottle(label: d.label, key: d.key, other: d.other))
        }
        if !onboarded { scannedInOnboarding = add + scannedInOnboarding }
        persist()
        showScanReview = false
        let after = canMake.count
        let plus = after > before && before > 0 ? " (+\(after - before))" : ""
        show("Added \(add.count) bottle\(add.count == 1 ? "" : "s") · \(after) drinks ready\(plus)")
    }

    private static var shelfURL: URL {
        URL.documentsDirectory.appending(path: "shelf.jpg")
    }

    /// Keeps a downscaled copy of the shelf photo for the Library card.
    private func keepShelf(_ image: UIImage) {
        let maxSide: CGFloat = 900
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let small = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        shelfPhoto = small
        try? small.jpegData(compressionQuality: 0.72)?.write(to: Self.shelfURL)
    }

    // MARK: Onboarding

    func nextOnboardingStep() {
        if onboardingStep == 1 {
            name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            persist()
        }
        onboardingStep = min(3, onboardingStep + 1)
    }

    func finishOnboarding(startTrial: Bool) {
        if startTrial { premium = true }
        onboarded = true
        tab = .home
        filter = canMake.isEmpty ? .all : .can
        persist()
        if startTrial { show("Premium trial started. This build never charges you.") }
    }

    func replayIntro() {
        onboarded = false
        onboardingStep = 0
        scannedInOnboarding = []
        viewfinderPhoto = nil
        persist()
    }

    // MARK: Ask the bartender

    var inventing = false
    let bartender = Bartender()

    /// Free accounts get a few asks a day. Premium is unlimited (the server still caps asks a minute).
    static let freeAsksPerDay = 3
    private var askDay = 0
    private var asksToday = 0

    private static var today: Int { Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0 }

    /// Asks left today on the free plan, or nil with Premium.
    var freeAsksLeft: Int? {
        guard !premium else { return nil }
        return askDay == Self.today ? max(0, Self.freeAsksPerDay - asksToday) : Self.freeAsksPerDay
    }

    func askTheBartender() async {
        let keys = haveKeys.sorted()
        guard !keys.isEmpty else {
            show("Add some bottles to your library first.")
            return
        }
        guard !inventing else { return }
        if freeAsksLeft == 0 {
            show("That’s today’s \(Self.freeAsksPerDay) free asks. Premium has unlimited.")
            return
        }
        inventing = true
        Sounds.shake()
        defer { inventing = false }
        do {
            let drinks = try await bartender.invent(from: keys, avoid: invented.map(\.name), catalog: catalog)
            invented = Array((drinks + invented).prefix(12))
            if askDay != Self.today {
                askDay = Self.today
                asksToday = 0
            }
            asksToday += 1
            persist()
            Haptics.poured()
            Sounds.tada()
            show("\(drinks.count) new drinks added")
        } catch let error as Bartender.Failure {
            Haptics.failed()
            show(error.message)
        } catch {
            Haptics.failed()
            show("The bartender couldn’t come up with anything. Try again.")
        }
    }

    /// Deletes a drink the bartender invented, and takes it out of Saved.
    func deleteInvented(_ recipe: Recipe) {
        guard recipe.isInvented else { return }
        Sounds.dink()
        invented.removeAll { $0.id == recipe.id }
        saved.removeAll { $0 == recipe.id }
        persist()
        Haptics.removed()
        show("\(recipe.name) deleted")
    }

    // MARK: Shopping list

    func isOnList(_ key: String) -> Bool { shopping.contains { $0.key == key } }

    /// How many more drinks the bar could make with this bottle added.
    func unlocks(_ key: String?) -> Int {
        guard let key, !has(key) else { return 0 }
        let have = haveKeys.union([key])
        return allRecipes.filter { recipe in
            let needs = Recipe.bottleKeys(recipe.ing)
            return needs.contains(key) && needs.allSatisfy(have.contains)
        }.count
    }

    /// Adds a catalog bottle a recipe needs.
    func addToList(key: String) {
        guard !isOnList(key), let b = catalog.bottle(key) else { return }
        shopping.append(ShoppingItem(name: b.name, key: key))
        persist()
        Haptics.saved()
        show("\(b.name) added to your shopping list")
    }

    /// Takes a bottle off the shelf and puts it on the shopping list.
    func moveToList(_ bottle: BarBottle) {
        bar.removeAll { $0.id == bottle.id }
        let name = catalog.bottle(bottle.key)?.name ?? bottle.label
        let already = shopping.contains { item in
            bottle.key.map { item.key == $0 } ?? (item.name.lowercased() == name.lowercased())
        }
        if !already { shopping.append(ShoppingItem(name: name, key: bottle.key)) }
        persist()
        Haptics.saved()
        show("\(name) moved to your shopping list")
    }

    func removeFromList(_ item: ShoppingItem) {
        shopping.removeAll { $0.id == item.id }
        persist()
        Haptics.removed()
    }

    func removeFromList(key: String) {
        guard let item = shopping.first(where: { $0.key == key }) else { return }
        removeFromList(item)
    }

    /// Bought it: off the list and onto the shelf.
    func bought(_ item: ShoppingItem) {
        shopping.removeAll { $0.id == item.id }
        let before = canMake.count
        if item.key == nil || !has(item.key!) {
            bar.append(BarBottle(label: item.name, key: item.key))
        }
        persist()
        Haptics.saved()
        let gained = canMake.count - before
        show("\(item.name) is on your shelf" + (gained > 0 ? " · +\(gained) drinks" : ""))
    }

    /// The list as plain text, for Messages or Notes.
    var shoppingText: String {
        "Swizzle shopping list\n" + shopping.map { "• \($0.name)" }.joined(separator: "\n")
    }

    // MARK: Toast

    func show(_ message: String) {
        withAnimation(.snappy) { toast = message }
    }
}
