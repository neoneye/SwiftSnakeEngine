// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import EngineIOS

enum PlayerMode: String, CaseIterable {
    case twoPlayer_humanBot = "twoPlayer_humanBot"
    case singlePlayer_human = "singlePlayer_human"
}

/// Keeps track of the users preferred `player mode`.
class PlayerModeController {
    private(set) lazy var currentPlayerMode = loadMode()
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

    private func loadMode() -> PlayerMode {
        let rawValue: String? = defaults.string(forKey: defaultsKey)
        let playerMode: PlayerMode = rawValue.flatMap(PlayerMode.init) ?? .twoPlayer_humanBot
        log.debug("get player mode: \(playerMode)")
        return playerMode
    }
}
