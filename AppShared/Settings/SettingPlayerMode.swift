// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

enum SettingPlayerModeValue: String {
    case twoPlayer_humanBot = "twoPlayer_humanBot"
    case singlePlayer_human = "singlePlayer_human"
}

/// Keeps track of the users preferred `player mode`.
class SettingPlayerMode {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SNAKE_PLAYERMODE"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(_ newValue: SettingPlayerModeValue) {
        value = newValue
        defaults.setValue(newValue.rawValue, forKey: defaultsKey)
    }

    private func initialValue() -> SettingPlayerModeValue {
        let rawValue: String? = defaults.string(forKey: defaultsKey)
        return rawValue.flatMap(SettingPlayerModeValue.init) ?? .twoPlayer_humanBot
    }
}
