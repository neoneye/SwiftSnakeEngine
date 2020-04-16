// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import SpriteKit

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

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
    @ObservedObject var model: MyModel

    init(model: MyModel) {
        self.model = model
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    var onSendInfoEvent: ((_ event: SnakeGameInfoEvent) -> Void)?

    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        onSendInfoEvent?(event)
    }
}

extension SKScene {
    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        guard let skView: SnakeGameSKView = self.view as? SnakeGameSKView else {
            log.error("Expected self.view to be of type SnakeGameSKView. Cannot send info event: \(event)")
            return
        }
//        log.debug("send info event: \(event)")
        skView.sendInfoEvent(event)
    }

    func transitionToLevelSelectorScene() {
        let transition = SKTransition.doorway(withDuration: 0.75)
        let newScene = SnakeLevelSelectorScene.create()
        view?.presentScene(newScene, transition: transition)
    }
}
