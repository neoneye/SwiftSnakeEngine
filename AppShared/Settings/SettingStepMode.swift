// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

enum SettingStepModeValue: String {
    case stepManual = "manual"
    case stepAuto = "auto"
}

/// Keeps track of the users preferred `step mode`.
class SettingStepMode {
    private(set) lazy var value = initialValue()
    private let defaults: UserDefaults
    private let defaultsKey = "SNAKE_STEPMODE"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(_ newValue: SettingStepModeValue) {
        value = newValue
        defaults.setValue(newValue.rawValue, forKey: defaultsKey)
    }

    private func initialValue() -> SettingStepModeValue {
        let rawValue: String? = defaults.string(forKey: defaultsKey)
        return rawValue.flatMap(SettingStepModeValue.init) ?? .stepAuto
    }
}
