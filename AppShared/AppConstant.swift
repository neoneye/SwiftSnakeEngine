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
    enum Mode: Equatable {
		case production
        case develop_ingame
        case develop_replay(resourceName: String)
        case develop_runDatasetCompiler(version: UInt)

        static func ==(lhs: Mode, rhs: Mode) -> Bool {
            switch (lhs, rhs) {
            case (.production, .production):
                return true
            case (.develop_ingame, .develop_ingame):
                return true
            case (let .develop_replay(name0), let .develop_replay(name1)):
                return name0 == name1
            case (let .develop_runDatasetCompiler(version0), let .develop_runDatasetCompiler(version1)):
                return version0 == version1
            default:
                return false
            }
        }
	}
	static let mode: Mode = .production
    //static let mode: Mode = .develop_replay(resourceName: "duel8.snakeDataset")
    //static let mode: Mode = .develop_replay(resourceName: "solo0.snakeDataset")
//    static let mode: Mode = .develop_runDatasetCompiler(version: 1)

    static var escapeKeyToTerminateApp: Bool {
        switch mode {
        case .production:
            return false
        case .develop_ingame:
            return true
        case .develop_replay:
            return true
        case .develop_runDatasetCompiler:
            return true
        }
    }

	static let ignoreRepeatingKeyDownEvents = true

    struct Dashboard {
        static let url = URL(string: "http://localhost:4000/")!
    }
}
