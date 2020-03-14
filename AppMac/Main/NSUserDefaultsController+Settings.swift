// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa

extension NSUserDefaultsController {
	@objc dynamic var isSoundEffectsEnabled: Bool {
		set {
			defaults.set(newValue, forKey: "isSoundEffectsEnabled")
		}
		get {
			if defaults.object(forKey: "isSoundEffectsEnabled") == nil {
				return true
			}
			return defaults.bool(forKey: "isSoundEffectsEnabled")
		}
	}

	var selectedLevelIndex: Int {
		set {
			defaults.set(newValue, forKey: "selectedLevelIndex")
		}
		get {
			return defaults.integer(forKey: "selectedLevelIndex")
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
