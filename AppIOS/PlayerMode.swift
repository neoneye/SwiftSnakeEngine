// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import EngineIOS

enum PlayerMode: String {
    case twoPlayer_humanBot = "twoPlayer_humanBot"
    case singlePlayer_human = "singlePlayer_human"
}

/// Keeps track of the users preferred `player mode`.
class PlayerModeController {
    private(set) lazy var currentPlayerMode = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SNAKE_PLAYERMODE"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func changePlayerMode(to playerMode: PlayerMode) {
        log.debug("set player mode: \(playerMode)")
        currentPlayerMode = playerMode
        defaults.setValue(playerMode.rawValue, forKey: defaultsKey)
    }

    private func initialValue() -> PlayerMode {
        let rawValue: String? = defaults.string(forKey: defaultsKey)
        let value: PlayerMode = rawValue.flatMap(PlayerMode.init) ?? .twoPlayer_humanBot
        log.debug("get player mode: \(value)")
        return value
    }
}
