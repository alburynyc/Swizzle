import AVFoundation

/// The app's sound effects, from Garrett's recordings in Resources/Sounds. They use the ambient
/// audio session, so they mix with music and stay quiet when the ringer switch is on silent.
@MainActor
enum Sounds {
    /// Bookmarking or unbookmarking a recipe.
    static func pop() { play("Pop") }

    /// Tapping Ask the bartender.
    static func shake() { play("Shaker") }

    /// The bartender's new drinks arriving.
    static func tada() {
        players["Shaker"]?.stop()
        play("Tada")
    }

    /// Deleting a bartender drink.
    static func dink() { play("Dink") }

    private static var players: [String: AVAudioPlayer] = [:]
    private static var sessionReady = false

    private static func play(_ name: String) {
        if !sessionReady {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            sessionReady = true
        }
        if players[name] == nil,
           let url = Bundle.main.url(forResource: name, withExtension: "m4a"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.prepareToPlay()
            players[name] = player
        }
        guard let player = players[name] else { return }
        player.currentTime = 0
        player.play()
    }
}
