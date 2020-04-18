// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import EngineIOS

enum PlayerMode: String {
    case twoPlayer_humanBot = "twoPlayer_humanBot"
    case singlePlayer_human = "singlePlayer_human"
}

/// Keeps track of the users preferred `player mode`.
class PlayerModeController {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SNAKE_PLAYERMODE"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(_ newValue: PlayerMode) {
        value = newValue
        defaults.setValue(newValue.rawValue, forKey: defaultsKey)
    }

    private func initialValue() -> PlayerMode {
        let rawValue: String? = defaults.string(forKey: defaultsKey)
        return rawValue.flatMap(PlayerMode.init) ?? .twoPlayer_humanBot
    }
}
