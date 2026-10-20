import Foundation
import FoundationModels

/// Ask the bartender: invents three new drinks from the bottles on the shelf with Apple's on-device
/// model, so it works offline with no server or API key. Needs an iPhone with Apple Intelligence.
enum Bartender {
    struct Failure: Error {
        let message: String
    }

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

    static func invent(from keys: [String], catalog: Catalog) async throws -> [Recipe] {
        if let reason = unavailableReason { throw Failure(message: reason + ".") }

        let bottles = keys.map { "\($0) = \(catalog.bottle($0)?.name ?? $0)" }.joined(separator: "\n")
        let session = LanguageModelSession(instructions: """
            You are the bartender in a cocktail app called Swizzle. You invent original, balanced \
            cocktails that someone can make at home with what they already have.
            """)
        let prompt = """
            Invent 3 original cocktails that use ONLY these bottles (any subset, at least one per drink). \
            Each bottle is written as key = name:
            \(bottles)

            You may also use common fridge and pantry items: citrus juice, simple syrup, honey, agave, sugar, \
            soda water, tonic, ginger beer, fruit juices, fresh herbs, fruit, egg white, salt, spices, coffee and tea.
            Don't reproduce well-known classics such as the Negroni, Margarita, Martini, Mojito, Old Fashioned \
            or Spritz. Give each a short, elegant name, and vary the styles.
            """
        let menu = try await session.respond(to: prompt, generating: Menu.self).content

        let stamp = Int(Date().timeIntervalSince1970)
        let drinks = menu.drinks.prefix(3).enumerated().compactMap { index, drink in
            recipe(from: drink, id: "ai-\(stamp)-\(index)", allowed: Set(keys))
        }
        if drinks.isEmpty { throw Failure(message: "The bartender couldn’t come up with anything. Try again.") }
        return drinks
    }

    /// Turns the model's answer into a recipe, dropping anything that doesn't fit the catalog's rules.
    private static func recipe(from drink: Drink, id: String, allowed: Set<String>) -> Recipe? {
        let ing = drink.ingredients.compactMap { x -> Ingredient? in
            let item = x.item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !item.isEmpty else { return nil }
            let key = x.bottle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return Ingredient(amount: String(x.amount.prefix(20)), item: String(item.prefix(50)),
                              bottle: allowed.contains(key) ? key : nil, ml: nil)
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
                      ing: ing, steps: Array(steps), source: nil, alt: nil, colors: Array(colors.prefix(4)))
    }

    // What the model fills in.

    @Generable
    struct Menu {
        @Guide(description: "Exactly three original cocktails")
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
        @Guide(description: "What it is, such as Gin or Lime juice")
        var item: String
        @Guide(description: "For a bottle, its key from the list of bottles. For anything else, write none")
        var bottle: String
    }

    @Generable
    struct DrinkStep {
        @Guide(description: "One short verb in capitals, such as SHAKE, STIR, STRAIN, POUR, TOP, BUILD, MUDDLE or GARNISH")
        var verb: String
        @Guide(description: "One clear sentence")
        var text: String
    }
}
