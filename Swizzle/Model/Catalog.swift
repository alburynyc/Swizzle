import Foundation

// The recipe and bottle data. Resources/recipes.json and Resources/bottles.json are copies of the
// project's shared catalog; update them from there rather than editing them here.

struct Bottle: Codable, Identifiable, Hashable {
    let key: String
    let name: String
    let group: String
    let aliases: [String]

    var id: String { key }
}

struct Ingredient: Codable, Hashable {
    let amount: String
    let item: String
    /// The bottle this ingredient needs. Nil means pantry (citrus, syrups, soda, juice, cream, egg, herbs).
    let bottle: String?
    let ml: Double?
}

struct Step: Codable, Hashable {
    let verb: String
    let text: String
}

struct RecipeSource: Codable, Hashable {
    let name: String
    let url: String?
    let note: String?
}

/// A Swizzle variation shown as a second version of a recipe, e.g. Negroni Sbagliato.
struct Variation: Codable, Hashable {
    let name: String
    let note: String?
    let ing: [Ingredient]
    let steps: [Step]
}

struct Recipe: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let cats: [String]
    let glass: String
    let ing: [Ingredient]
    let steps: [Step]
    let source: RecipeSource?
    let alt: Variation?
}

private struct RecipeFile: Decodable {
    let glasses: [String: String]
    let recipes: [Recipe]
}

private struct BottleFile: Decodable {
    let groups: [String]
    let bottles: [Bottle]
}

/// A catalog bottle that typed text could be, and the brand name that matched, if any.
struct BottleGuess: Hashable {
    let key: String
    let why: String?
}

struct Catalog {
    let recipes: [Recipe]
    let bottles: [Bottle]
    let groups: [String]
    let glassNames: [String: String]
    private let bottlesByKey: [String: Bottle]
    private let recipesByID: [String: Recipe]
    /// Normalized brand names, label words and bottle names, longest first, used to read labels.
    let labelTerms: [(term: String, key: String)]

    static let shared = Catalog.load()

    private static func load() -> Catalog {
        let decoder = JSONDecoder()
        func read<T: Decodable>(_ name: String) -> T {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                fatalError("Missing \(name).json in the app bundle")
            }
            do { return try decoder.decode(T.self, from: data) }
            catch { fatalError("Couldn't read \(name).json: \(error)") }
        }
        let r: RecipeFile = read("recipes")
        let b: BottleFile = read("bottles")
        return Catalog(recipes: r.recipes, bottles: b.bottles, groups: b.groups, glassNames: r.glasses)
    }

    init(recipes: [Recipe], bottles: [Bottle], groups: [String], glassNames: [String: String]) {
        self.recipes = recipes
        self.bottles = bottles
        self.groups = groups
        self.glassNames = glassNames
        bottlesByKey = Dictionary(uniqueKeysWithValues: bottles.map { ($0.key, $0) })
        recipesByID = Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, $0) })
        var terms: [(term: String, key: String)] = []
        for bottle in bottles {
            terms.append((term: Self.normalize(bottle.name), key: bottle.key))
            for alias in bottle.aliases {
                terms.append((term: Self.normalize(alias), key: bottle.key))
            }
        }
        labelTerms = terms.filter { !$0.term.isEmpty }.sorted { $0.term.count > $1.term.count }
    }

    func bottle(_ key: String?) -> Bottle? {
        guard let key else { return nil }
        return bottlesByKey[key]
    }

    func recipe(_ id: String) -> Recipe? { recipesByID[id] }

    func bottles(in group: String) -> [Bottle] { bottles.filter { $0.group == group } }

    /// Lowercase, accents folded, punctuation turned into spaces: "Ford's Gin" becomes "ford s gin".
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        let spaced = folded.map { $0.isLetter || $0.isNumber || $0 == "&" ? $0 : " " }
        return String(spaced).split(separator: " ").joined(separator: " ")
    }

    /// Bottle kinds that a typed name could be, best first. Used by search and "What is this bottle?".
    func guesses(for text: String) -> [BottleGuess] {
        let s = Self.normalize(text)
        guard !s.isEmpty else { return [] }
        var hits: [BottleGuess] = []
        for bottle in bottles {
            let n = Self.normalize(bottle.name)
            if s.contains(n) || n.contains(s) { hits.append(BottleGuess(key: bottle.key, why: nil)) }
        }
        for bottle in bottles where !hits.contains(where: { $0.key == bottle.key }) {
            if let alias = bottle.aliases.first(where: {
                let a = Self.normalize($0)
                return s.contains(a) || (s.count >= 3 && a.hasPrefix(s))
            }) {
                hits.append(BottleGuess(key: bottle.key, why: alias))
            }
        }
        return Array(hits.prefix(6))
    }
}

extension Recipe {
    /// The distinct bottles a version of this recipe needs.
    static func bottleKeys(_ ing: [Ingredient]) -> [String] {
        var seen = Set<String>()
        return ing.compactMap(\.bottle).filter { seen.insert($0).inserted }
    }

    /// The first spirit in the recipe, or its first bottle when it has no spirit. Shown as a tag.
    func baseSpirit(_ ing: [Ingredient]? = nil) -> String {
        let keys = Recipe.bottleKeys(ing ?? self.ing)
        let catalog = Catalog.shared
        let key = keys.first { catalog.bottle($0)?.group == "Spirits" } ?? keys.first
        return catalog.bottle(key)?.name ?? ""
    }

    var styleTag: String {
        if cats.contains("brunch") { return "Brunch" }
        if cats.contains("spirit") { return "Classic" }
        return "Fresh"
    }

    var glassLabel: String {
        if glass == "mug" { return "Mug" }
        return "\(Catalog.shared.glassNames[glass] ?? glass.capitalized) glass"
    }
}
