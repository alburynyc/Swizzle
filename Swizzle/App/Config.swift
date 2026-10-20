import Foundation

enum Config {
    /// The bartender server's address, printed by `npm run deploy` in the `server` folder, such as
    /// "https://swizzle-bartender.yourname.workers.dev". Left empty, Ask the bartender uses Apple's
    /// on-device model only.
    static let bartenderServer = ""

    static var bartenderURL: URL? {
        bartenderServer.isEmpty ? nil : URL(string: bartenderServer)?.appending(path: "bartender")
    }
}
