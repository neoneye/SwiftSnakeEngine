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
        case develop_replay(resourceName: String)
	}
	static let mode: Mode = .production
    //static let mode: Mode = .develop_replay(resourceName: "duel8.snakeDataset")
    //static let mode: Mode = .develop_replay(resourceName: "solo0.snakeDataset")

    static var escapeKeyToTerminateApp: Bool {
        switch mode {
        case .production:
            return false
        case .develop_ingame:
            return true
        case .develop_replay:
            return true
        }
    }

	static let ignoreRepeatingKeyDownEvents = true

    struct Dashboard {
        static let url = URL(string: "http://localhost:4000/")!
    }
}
