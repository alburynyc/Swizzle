import Foundation
import FoundationModels

/// Ask the bartender: invents three new drinks from the bottles on the shelf with Apple's on-device
/// model, so it works offline with no server or API key. Needs an iPhone with Apple Intelligence.
@MainActor
final class Bartender {
    struct Failure: Error {
        let message: String
    }

    static let drinksPerAsk = 3

    /// A session loaded ahead of time, so the first answer starts sooner.
    private var warmSession: LanguageModelSession?

    /// Why the bartender can't work on this device, or nil when it can.
    static var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "Needs an iPhone with Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in Settings to use this"
        case .unavailable(.modelNotReady):
            return "Apple Intelligence is still downloading. Try again soon"
        case .unavailable:
            return "Not available on this iPhone"
        @unknown default:
            return "Not available on this iPhone"
        }
    }

    private static let instructions = """
        You are the bartender in a cocktail app called Swizzle. You invent original, balanced cocktails \
        that someone can make at home with only the bottles they say they have, plus fridge and pantry items.
        """

    /// Loads the model while the person looks at For You.
    func prewarm() {
        guard Self.unavailableReason == nil, warmSession == nil else { return }
        let session = LanguageModelSession(instructions: Self.instructions)
        session.prewarm()
        warmSession = session
    }

    func invent(from keys: [String], catalog: Catalog) async throws -> [Recipe] {
        if let reason = Self.unavailableReason { throw Failure(message: reason + ".") }
        let session = warmSession ?? LanguageModelSession(instructions: Self.instructions)
        warmSession = nil
        defer { prewarm() }

        let bottles = keys.map { catalog.bottle($0)?.name ?? $0 }.joined(separator: ", ")
        let stamp = Int(Date().timeIntervalSince1970)
        var drinks: [Recipe] = []
        // The small model sometimes slips in a bottle that isn't on the shelf. Those drinks are
        // dropped, and it's asked once more for replacements.
        for attempt in 0..<2 where drinks.count < Self.drinksPerAsk {
            let wanted = Self.drinksPerAsk - drinks.count
            let prompt = attempt == 0 ? """
                The bottles on my shelf: \(bottles).
                Invent \(wanted) original cocktails. Every alcoholic ingredient must be one of those bottles, \
                written with exactly that name. Any other ingredient must be a fridge or pantry item: citrus juice, \
                simple syrup, honey, agave, sugar, soda water, tonic, ginger beer, fruit juice, fresh herbs, \
                fruit, egg white, salt, spices, coffee or tea. Don't use any other spirit, liqueur, wine or bitters.
                Don't reproduce well-known classics such as the Negroni, Margarita, Martini, Mojito, Old Fashioned \
                or Spritz. Give each a short, elegant name, and vary the styles.
                """ : """
                I need \(wanted) more original cocktails, different from those. \
                For the alcohol, use only \(bottles), written with exactly those names.
                """
            let menu: Menu
            do {
                menu = try await session.respond(to: prompt, generating: Menu.self).content
            } catch {
                // Keep what the first round made if the follow-up fails.
                if drinks.isEmpty { throw error }
                break
            }
            for drink in menu.drinks where drinks.count < Self.drinksPerAsk {
                if let recipe = Self.recipe(from: drink, id: "ai-\(stamp)-\(drinks.count)", shelf: Set(keys), catalog: catalog),
                   !drinks.contains(where: { $0.name == recipe.name }) {
                    drinks.append(recipe)
                }
            }
        }
        if drinks.isEmpty { throw Failure(message: "The bartender couldn’t come up with anything. Try again.") }
        return drinks
    }

    /// Turns the model's answer into a recipe. Each ingredient's bottle is worked out from its name, not
    /// taken on the model's word, and a drink that needs a bottle that isn't on the shelf is dropped.
    private static func recipe(from drink: Drink, id: String, shelf: Set<String>, catalog: Catalog) -> Recipe? {
        var ing: [Ingredient] = []
        for x in drink.ingredients {
            let item = x.item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !item.isEmpty else { continue }
            var key: String?
            switch classify(item, catalog: catalog) {
            case .pantry: key = nil
            case .bottle(let k): key = k
            case .unknownAlcohol: return nil
            }
            if let key, !shelf.contains(key) { return nil }
            ing.append(Ingredient(amount: String(x.amount.prefix(20)), item: String(item.prefix(50)), bottle: key, ml: nil))
        }
        let steps = drink.steps.prefix(5).compactMap { s -> Step? in
            let text = s.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            let verb = String(s.verb.uppercased().filter(\.isLetter).prefix(7))
            return Step(verb: verb.isEmpty ? "STEP" : verb, text: String(text.prefix(240)))
        }
        let name = drink.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !steps.isEmpty, !Recipe.bottleKeys(ing).isEmpty else { return nil }

        let glass = drink.glass.lowercased().filter(\.isLetter)
        let cats = drink.categories.map { $0.lowercased() }.filter { ["color", "fruity", "spirit", "brunch"].contains($0) }
        let colors = drink.colors.map { $0.trimmingCharacters(in: .whitespaces) }.filter { c in
            c.count == 7 && c.first == "#" && c.dropFirst().allSatisfy(\.isHexDigit)
        }
        return Recipe(id: id, name: String(name.prefix(40)), cats: Array(cats.prefix(2)),
                      glass: GlassType(rawValue: glass) != nil ? glass : "rocks",
                      ing: ing, steps: steps, source: nil, alt: nil, colors: Array(colors.prefix(4)))
    }

    /// Re-reads each ingredient's bottle from its name. Drinks saved by the first version of this
    /// feature trusted the model's bottle keys, which could mark a missing bottle as "in your bar".
    static func checked(_ recipe: Recipe, catalog: Catalog) -> Recipe {
        let ing = recipe.ing.map { x -> Ingredient in
            guard case .bottle(let key) = classify(x.item, catalog: catalog) else { return x.with(bottle: nil) }
            return x.with(bottle: key)
        }
        return Recipe(id: recipe.id, name: recipe.name, cats: recipe.cats, glass: recipe.glass, ing: ing,
                      steps: recipe.steps, source: recipe.source, alt: recipe.alt, colors: recipe.colors)
    }

    /// Syrups, juices and the like are pantry even when they share a word with a liqueur
    /// ("elderflower cordial", "coffee syrup").
    private static let pantryWords = ["syrup", "juice", "cordial", "tonic", "soda", "puree", "purée", "water", "cream", "tea"]

    private static let alcoholWords = ["rum", "whiskey", "whisky", "brandy", "liqueur", "vermouth", "wine", "bitters",
                                       "gin", "vodka", "tequila", "mezcal", "amaro", "aperitivo", "schnapps", "cognac",
                                       "champagne", "prosecco", "sherry", "port", "absinthe", "scotch", "bourbon", "rye"]

    private enum Kind { case pantry, bottle(String), unknownAlcohol }

    private static func classify(_ item: String, catalog: Catalog) -> Kind {
        let words = Set(Catalog.normalize(item).split(separator: " ").map(String.init))
        if pantryWords.contains(where: { words.contains($0) }) { return .pantry }
        if let key = catalog.bottleKey(named: item) { return .bottle(key) }
        // Alcohol the catalog can't place can't be checked against the shelf.
        if alcoholWords.contains(where: { words.contains($0) }) { return .unknownAlcohol }
        return .pantry
    }

    // What the model fills in.

    @Generable
    struct Menu {
        @Guide(description: "The cocktails asked for")
        var drinks: [Drink]
    }

    @Generable
    struct Drink {
        @Guide(description: "A short, elegant name for a new drink, not a well-known classic")
        var name: String
        @Guide(description: "The glass: one of rocks, highball, collins, coupe, martini, nicknora, margarita, flute, wine, hurricane, snifter or cordial")
        var glass: String
        @Guide(description: "One or two of: color, fruity, spirit, brunch")
        var categories: [String]
        @Guide(description: "Three or four vivid hex colors such as #C8102E, taken from this drink's own ingredients, most prominent first")
        var colors: [String]
        @Guide(description: "Two to six ingredients")
        var ingredients: [DrinkIngredient]
        @Guide(description: "Two to four steps")
        var steps: [DrinkStep]
    }

    @Generable
    struct DrinkIngredient {
        @Guide(description: "The amount, such as 1.5 oz, 2 dashes or 1 barspoon")
        var amount: String
        @Guide(description: "What it is. For a bottle, use exactly the name from my shelf. Otherwise a pantry item such as Lime juice")
        var item: String
    }

    @Generable
    struct DrinkStep {
        @Guide(description: "One short verb in capitals, such as SHAKE, STIR, STRAIN, POUR, TOP, BUILD, MUDDLE or GARNISH")
        var verb: String
        @Guide(description: "One clear sentence")
        var text: String
    }
}
