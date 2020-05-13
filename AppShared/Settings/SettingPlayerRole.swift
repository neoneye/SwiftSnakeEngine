// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

/// Player1's preferred `player role`, eg. human, bot3, bot5 or none.
class SettingPlayer1Role: SettingPlayerRole {
    init(defaults: UserDefaults = .standard) {
        super.init(defaultsKey: "SNAKE_PLAYER1_ROLE", defaults: defaults)
    }
}

/// Player2's preferred `player role`, eg. human, bot3, bot5 or none.
class SettingPlayer2Role: SettingPlayerRole {
    init(defaults: UserDefaults = .standard) {
        super.init(defaultsKey: "SNAKE_PLAYER2_ROLE", defaults: defaults)
    }
}

class SettingPlayerRole {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey: String

    init(defaultsKey: String, defaults: UserDefaults = .standard) {
        self.defaultsKey = defaultsKey
        self.defaults = defaults
    }

    func set(_ newValue: SnakePlayerRole) {
        let uuid0: UUID = value.id
        let uuid1: UUID = newValue.id
        guard uuid0 != uuid1 else {
            return
        }
        let string: String = newValue.id.uuidString
        value = newValue
        defaults.set(string, forKey: defaultsKey)
    }

    private func initialValue() -> SnakePlayerRole {
        guard let uuidString: String = defaults.string(forKey: defaultsKey) else {
            return SnakePlayerRole.human
        }
        guard let uuid: UUID = UUID(uuidString: uuidString) else {
            return SnakePlayerRole.human
        }
        guard let role: SnakePlayerRole = SnakePlayerRole.create(uuid: uuid) else {
            return SnakePlayerRole.human
        }
        return role
    }
}

