// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa

extension NSUserDefaultsController {
	@objc dynamic var isSoundEffectsEnabled: Bool {
		set {
            SettingSoundEffect().set(newValue)
		}
		get {
            return SettingSoundEffect().value
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
