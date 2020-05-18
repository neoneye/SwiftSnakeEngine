// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

/// Keeps track of the users preferred `show planned path` mode.
class SettingShowPlannedPath {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SNAKE_SHOWPLANNEDPATH"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(_ newValue: Bool) {
        value = newValue
        defaults.set(newValue, forKey: defaultsKey)
    }

    private func initialValue() -> Bool {
        if defaults.object(forKey: defaultsKey) == nil {
            return true
        }
        return defaults.bool(forKey: defaultsKey)
    }
}
