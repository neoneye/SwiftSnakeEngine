// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import EngineMac

enum SnakeGameInfoEvent {
    case showLevelSelector
    case showLevelDetail(_ gameState: SnakeGameState)
    case beginNewGame(_ gameState: SnakeGameState)
    case player1_didUpdateLength(_ length: UInt)
    case player2_didUpdateLength(_ length: UInt)
    case player1_killed(_ killEvents: [SnakePlayerKillEvent])
    case player2_killed(_ killEvents: [SnakePlayerKillEvent])
}

class SnakeGameSKView: SKView {
    var onSendInfoEvent: ((_ event: SnakeGameInfoEvent) -> Void)?

    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        onSendInfoEvent?(event)
    }
}

extension SKScene {
    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        guard let sceneView: SnakeGameSKView = scene?.view as? SnakeGameSKView else {
            return
        }
        sceneView.sendInfoEvent(event)
    }
}
