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
    case player1_dead(_ causesOfDeath: [SnakeCauseOfDeath])
    case player2_dead(_ causesOfDeath: [SnakeCauseOfDeath])
}

class SnakeGameSKView: SKView {
    @ObservedObject var model: GameViewModel

    init(model: GameViewModel) {
        self.model = model
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    #if os(macOS)
    /// Called whenever there are changes to Light/Dark appearance
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        AppColorManager.shared.resolveNSColors()
        self.model.userInterfaceStyle.send()
    }
    #endif
}

extension SKScene {
    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        guard let skView: SnakeGameSKView = self.view as? SnakeGameSKView else {
            log.error("Expected self.view to be of type SnakeGameSKView. Cannot send info event: \(event)")
            return
        }
//        log.debug("send info event: \(event)")
        skView.model.sendInfoEvent(event)
    }

    func transitionToLevelSelectorScene() {
        let transition = SKTransition.doorway(withDuration: 0.75)
        let newScene = LevelSelectorScene()
        view?.presentScene(newScene, transition: transition)
    }
}
