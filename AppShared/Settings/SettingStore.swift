// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import Combine

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

final class SettingStore: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()

    enum Key: String {
        case isSoundEffectsEnabled
    }

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    private let settingPlayer1Role: SettingPlayer1Role
    private let settingPlayer2Role: SettingPlayer2Role
    private let settingSelectedLevel: SettingSelectedLevel

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in ()
                log.debug("UserDefaults did changed")
            }
            .subscribe(objectWillChange)

        self.settingPlayer1Role = SettingPlayer1Role(defaults: defaults)
        self.settingPlayer2Role = SettingPlayer2Role(defaults: defaults)
        self.settingSelectedLevel = SettingSelectedLevel(defaults: defaults)
    }

    var isSoundEffectsEnabled: Bool {
        get {
            if defaults.object(forKey: Key.isSoundEffectsEnabled.rawValue) == nil {
                return true
            }
            return defaults.bool(forKey: Key.isSoundEffectsEnabled.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Key.isSoundEffectsEnabled.rawValue)
        }
    }

    var player1Role: SnakePlayerRole {
        get {
            settingPlayer1Role.value
        }
        set {
            settingPlayer1Role.set(newValue)
        }
    }

    var player2Role: SnakePlayerRole {
        get {
            settingPlayer2Role.value
        }
        set {
            settingPlayer2Role.set(newValue)
        }
    }

    var selectedLevel: UInt {
        get {
            settingSelectedLevel.value
        }
        set {
            settingSelectedLevel.set(newValue)
        }
    }
}
