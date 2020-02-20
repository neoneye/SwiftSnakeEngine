// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SpriteKit
import SwiftUI
import SnakeGame
import Combine

enum SnakeGameInfoEvent {
    case beginNewGame(_ gameState: SnakeGameState)
    case player1_didUpdateLength(_ length: UInt)
    case player2_didUpdateLength(_ length: UInt)
    case player1_killed(_ killEvents: [SnakePlayerKillEvent])
    case player2_killed(_ killEvents: [SnakePlayerKillEvent])
}

class MySKView: SKView {
    var onSendInfoEvent: ((_ event: SnakeGameInfoEvent) -> Void)?

    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        onSendInfoEvent?(event)
    }
}

struct SpriteKitContainer: NSViewRepresentable {
    @Binding var player1Length: UInt
    @Binding var player2Length: UInt
    @Binding var player1Info: String
    @Binding var player2Info: String
	var isPreview: Bool = false

    class Coordinator: NSObject {
        var parent: SpriteKitContainer

        init(_ parent: SpriteKitContainer) {
            self.parent = parent
        }

        func sendInfoEvent(_ event: SnakeGameInfoEvent) {
            switch event {
            case let .beginNewGame(gameState):
                parent.player1Info = ""
                parent.player2Info = ""
                parent.player1Length = gameState.player1.lengthOfInstalledSnake()
                parent.player2Length = gameState.player2.lengthOfInstalledSnake()
            case let .player1_didUpdateLength(length):
                parent.player1Length = length
            case let .player2_didUpdateLength(length):
                parent.player2Length = length
            case let .player1_killed(killEvents):
                let deathExplanations: [String] = killEvents.map { $0.humanReadableDeathExplanation }
                let info: String = deathExplanations.joined(separator: "\n-\n")
                parent.player1Info = info
            case let .player2_killed(killEvents):
                let deathExplanations: [String] = killEvents.map { $0.humanReadableDeathExplanation }
                let info: String = deathExplanations.joined(separator: "\n-\n")
                parent.player2Info = info
            }
        }
    }

	func makeCoordinator() -> Coordinator {
		return Coordinator(self)
	}

	func makeNSView(context: Context) -> MySKView {
		SnakeLevelManager.setup()
		let view = MySKView(frame: .zero)
        view.onSendInfoEvent = { (event: SnakeGameInfoEvent) in
            context.coordinator.sendInfoEvent(event)
        }
		if isPreview {
			view.preferredFramesPerSecond = 1
		} else {
			view.preferredFramesPerSecond = 60
		}

        if AppConstant.SpriteKit.showDeveloperInfo {
            view.showsFPS = true
            view.showsNodeCount = true
        }

		view.ignoresSiblingOrder = true

		let scene: SKScene
		switch AppConstant.mode {
		case .production:
			scene = SnakeLevelSelectorScene.create()
		case .experimentWithAI:
			scene = SnakeGameScene.createBotsVsBots()
		}
		view.presentScene(scene)
		return view
	}


	func updateNSView(_ view: MySKView, context: Context) {
	}
}

struct SpriteKitContainer_Previews : PreviewProvider {

	static var previews: some View {
		Group {
            SpriteKitContainer(player1Length: .constant(3), player2Length: .constant(3), player1Info: .constant("TEST"), player2Info: .constant("TEST"), isPreview: true).previewLayout(.fixed(width: 125, height: 200))
			SpriteKitContainer(player1Length: .constant(3), player2Length: .constant(3), player1Info: .constant("TEST"), player2Info: .constant("TEST"), isPreview: true).previewLayout(.fixed(width: 150, height: 150))
			SpriteKitContainer(player1Length: .constant(3), player2Length: .constant(3), player1Info: .constant("TEST"), player2Info: .constant("TEST"), isPreview: true).previewLayout(.fixed(width: 200, height: 125))
		}
	}

}

extension SnakePlayerKillEvent {
    fileprivate var humanReadableDeathExplanation: String {
        let s0 = self.deathExplanation_title
        let s1 = self.deathExplanation_subtitle
        return s0 + "\n" + s1
    }
    
    fileprivate var deathExplanation_title: String {
        switch self {
        case .collisionWithWall:
            return "Death by wall!"
        case .collisionWithItself:
            return "Self-cannibalism!"
        case .collisionWithOpponent:
            return "Eating opponent!"
        case .noMoreFood:
            return "Starvation!"
        case .stuckInALoop:
            return "Stuck in a loop!"
        case .killAfterAFewTimeSteps:
            return "Autokill!"
        }
    }

    fileprivate var deathExplanation_subtitle: String {
        switch self {
        case .collisionWithWall:
            return "Cannot go through walls."
        case .collisionWithItself:
            return "Eating oneself is deadly."
        case .collisionWithOpponent:
            return "The snakes cannot eat each other, since it's deadly."
        case .noMoreFood:
            return "There is no more food."
        case .stuckInALoop:
            return "Expected the snake to make progress growing, but the snake continues doing the same moves over and over."
        case .killAfterAFewTimeSteps:
            return "Killed automatically after a few steps.\nThis is useful during development."
        }
    }
}
