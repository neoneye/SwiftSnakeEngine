// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Keeps track of the users preferred `show planned path` mode.
class SettingShowPlannedPath {
    private let defaults: UserDefaults
    private let defaultsKey = "SNAKE_SHOWPLANNEDPATH"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(_ newValue: Bool) {
        defaults.set(newValue, forKey: defaultsKey)
    }

    /// When this app runs on macOS, the NSMenu for "Show planned path"
    /// makes changes directly via NSUserDefaultsController, without going through this class.
    var value: Bool {
        if defaults.object(forKey: defaultsKey) == nil {
            return true
        }
        return defaults.bool(forKey: defaultsKey)
    }
}
