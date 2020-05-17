// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Keeps track of the users preferred `sound effect mode`, eg. muted or enabled.
class SettingSoundEffect {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SNAKE_SOUNDEFFECTS"

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
