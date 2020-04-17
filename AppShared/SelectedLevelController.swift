// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Remembers the selected level, so it's the same the next time the app is launched.
class SelectedLevelController {
    private(set) lazy var currentSelectedLevel = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SELECTED_LEVEL"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func changeSelectedLevel(to selectedLevel: Int) {
        currentSelectedLevel = selectedLevel
        defaults.setValue(Int(selectedLevel), forKey: defaultsKey)
    }

    private func initialValue() -> Int {
        return defaults.integer(forKey: defaultsKey)
    }
}
