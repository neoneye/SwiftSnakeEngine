// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa

extension NSUserDefaultsController {
	@objc dynamic var isSoundEffectsEnabled: Bool {
		set {
            defaults.set(newValue, forKey: SettingsStore.Key.isSoundEffectsEnabled.rawValue)
		}
		get {
			if defaults.object(forKey: SettingsStore.Key.isSoundEffectsEnabled.rawValue) == nil {
				return true
			}
			return defaults.bool(forKey: SettingsStore.Key.isSoundEffectsEnabled.rawValue)
		}
	}

	@objc dynamic var isShowPlannedPathEnabled: Bool {
		set {
			defaults.set(newValue, forKey: "isShowPlannedPathEnabled")
		}
		get {
			if defaults.object(forKey: "isShowPlannedPathEnabled") == nil {
				return true
			}
			return defaults.bool(forKey: "isShowPlannedPathEnabled")
		}
	}

}
