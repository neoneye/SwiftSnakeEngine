// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Remembers the selected level, so it's the same the next time the app is launched.
class SettingSelectedLevel {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SELECTED_LEVEL"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(_ newValue: Int) {
        value = newValue
        defaults.setValue(newValue, forKey: defaultsKey)
    }

    private func initialValue() -> Int {
        return defaults.integer(forKey: defaultsKey)
    }
}
