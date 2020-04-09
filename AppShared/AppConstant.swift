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
		case develop_humanVsNone
        case develop_botVsNone
	}
	static let mode: Mode = .production

	enum SnakeGameTheme {
		case theme1
		case theme2
	}
	static let theme: SnakeGameTheme = .theme1

	static let tileSize: CGFloat = 100

	static let killPlayer2AfterAFewSteps = false

	static let ignoreRepeatingKeyDownEvents = true

    enum GameInitialStepMode {
        // Similar to most video players that begins playing right away.
        // Immediately after selecting the level, the bot begins moving around.
        case production_stepForwardContinuously

        // Similar to single stepping with a debugger.
        // Nothing happens after selecting the level. The developer has to press F6 to single step.
        case doNothing
    }
    static let gameInitialStepMode: GameInitialStepMode = .production_stepForwardContinuously
//    static let gameInitialStepMode: GameInitialStepMode = .doNothing

	static let saveTrainingData = false

    struct SpriteKit {
        static let showDeveloperInfo = false
    }

    struct Dashboard {
        static let url = URL(string: "http://localhost:4000/")!
    }
}
