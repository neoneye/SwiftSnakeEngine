// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import CoreGraphics

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct AppConstant {
	enum Mode {
		case production
        case develop_ingame
	}
	static let mode: Mode = .production

    static var escapeKeyToTerminateApp: Bool {
        switch mode {
        case .production:
            return false
        case .develop_ingame:
            return true
        }
    }

	static let ignoreRepeatingKeyDownEvents = true

	static let saveTrainingData = true

    static let develop_showReplayOnPauseSheet = true

    struct Dashboard {
        static let url = URL(string: "http://localhost:4000/")!
    }
}
