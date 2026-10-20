# Swizzle

Your bottles. Better cocktail recipes. A native iOS app in SwiftUI.

## Run it

1. Open `Swizzle.xcodeproj` in Xcode 26 or later.
2. Pick the **Swizzle** scheme and an iPhone simulator (iOS 26+), then press Run.
3. To run on your own iPhone, choose your team under *Signing & Capabilities*.

The label scan needs a real camera, so on the simulator use **Upload** with a photo of some bottles instead.

## What's in it

- **First run:** Welcome, account (name only for now), capture your bar (camera or upload, or add by hand), and the Premium screen.
- **Home:** greeting, search, Today's picks, and every recipe filtered by *All*, *Can make now* and *One bottle away*.
- **For You:** saved recipes, plus the Ask the bartender card (not wired up yet).
- **Library:** your shelf photo, the bottles on your shelf, and every catalog bottle as a chip to add by hand.
- **Search:** by drink, bottle, brand or ingredient.
- **Recipe:** ingredients marked in or not in your bar, the method, the source, and the Swizzle variation where there is one.

Every recipe card, row, pick and recipe page has a bookmark. Saved recipes show up in For You.

## How it's built

| Folder | What's there |
| --- | --- |
| `Swizzle/App` | App entry point, tab bar, and the shared camera, photo and bottle sheets |
| `Swizzle/Model` | `Catalog` (reads the bundled JSON) and `AppStore` (your bar, saved recipes, matching) |
| `Swizzle/Design` | Colors, fonts, buttons, glass icons and recipe art |
| `Swizzle/Scan` | On-device label reading with Apple's Vision, plus the camera |
| `Swizzle/Views` | One file per screen, plus onboarding and the bottle sheets |
| `Swizzle/Resources` | `recipes.json` and `bottles.json` |

- **House style:** white and black only, Liquid Glass for the chrome (search fields, tab bar, pills, bookmarks), Times New Roman for display type and Helvetica Neue for everything else. Colors and fonts live in `Design/Theme.swift`.
- **Cocktail icons:** every drink without a photo shows its glass from the Figma board "Glassware — Cocktail icon library" (`Design/GlassIcon.swift`). Mugs use the Highball icon.
- **Photos:** only the Negroni, Old Fashioned and Dry Martini have photography so far, taken from the Figma file at 1x.
- **Matching:** a recipe needs every distinct `bottle` key in its ingredients. Anything without a key counts as pantry.
- **Label scan:** Vision reads the text in the photo on the device, and each line is matched against the brand names and label words in `bottles.json`. You then confirm or correct what it found.
- **Data:** `Resources/recipes.json` and `Resources/bottles.json` are copies of the project's shared catalog. Update them there first, then copy them in.
- **Storage:** everything stays on the device (`UserDefaults`, plus the shelf photo in Documents). There are no accounts or payments yet, and the free trial button only flips a local flag.
