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

final class SettingsStore: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()

    enum Key: String {
        case isSoundEffectsEnabled
        case player1RoleMenuItem
        case player2RoleMenuItem
    }

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in ()
                log.debug("UserDefaults did changed")
            }
            .subscribe(objectWillChange)
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
}
