// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SnakeGame

struct AppConstant {
	enum Mode {
		case production
		case experimentWithAI_botVsNone
	}
	static let mode: Mode = .experimentWithAI_botVsNone

	enum SnakeGameTheme {
		case theme1
		case theme2
	}
	static let theme: SnakeGameTheme = .theme1

	static let tileSize: CGFloat = 100

	static let killPlayer2AfterAFewSteps = false

	static let ignoreRepeatingKeyDownEvents = true

	static let saveTrainingData = false

    struct SpriteKit {
        static let showDeveloperInfo = false
    }
}
