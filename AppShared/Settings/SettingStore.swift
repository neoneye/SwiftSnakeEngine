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

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    private let settingPlayer1Role: SettingPlayer1Role
    private let settingPlayer2Role: SettingPlayer2Role
    private let settingSelectedLevel: SettingSelectedLevel
    private let settingPlayerMode: SettingPlayerMode
    private let settingStepMode: SettingStepMode

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
        self.settingPlayerMode = SettingPlayerMode(defaults: defaults)
        self.settingStepMode = SettingStepMode(defaults: defaults)
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

    var playerMode: SettingPlayerModeValue {
        get {
            settingPlayerMode.value
        }
        set {
            settingPlayerMode.set(newValue)
        }
    }

    var stepMode: SettingStepModeValue {
        get {
            settingStepMode.value
        }
        set {
            settingStepMode.set(newValue)
        }
    }
}
