// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Remembers the selected level, so it's the same the next time the app is launched.
///
/// IDEA: Use the uuid of level, so that it's the exact same level that is selected.
class SettingSelectedLevel {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SELECTED_LEVEL"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(_ newValue: UInt) {
        value = newValue
        defaults.setValue(Int(newValue), forKey: defaultsKey)
    }

    private func initialValue() -> UInt {
        let value: Int = defaults.integer(forKey: defaultsKey)
        guard value >= 0 else {
            return 0
        }
        return UInt(value)
    }
}
