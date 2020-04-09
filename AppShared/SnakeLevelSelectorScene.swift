// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

#if os(macOS)
import SSEventFlow
#endif

class SnakeLevelSelectorScene: SKScene {
	var contentCreated = false
	var needRedraw = false
	var needLayout = false
	var needBecomeFirstResponder = false
    var needSendingLevelInfo = true

	var levelSelectorNode: SnakeLevelSelectorNode

	class func create() -> SnakeLevelSelectorScene {
		let scene = SnakeLevelSelectorScene(size: CGSize.zero)
		scene.scaleMode = .resizeFill
		return scene
	}

	override init(size: CGSize) {
		self.levelSelectorNode = SnakeLevelSelectorNode.create()
		super.init(size: size)
	}

	required init?(coder aDecoder: NSCoder) {
		self.levelSelectorNode = SnakeLevelSelectorNode.create()
		super.init(coder: aDecoder)
	}

    #if os(macOS)
	override func mouseUp(with event: NSEvent) {
		launchGame()
	}
    #endif

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        launchGame()
    }
    #endif


	func launchGame() {
		guard let gameState: SnakeGameState = levelSelectorNode.gameStateForSelectedIndex() else {
			log.error("Expected gameStateForSelectedIndex() to be non-nil, but got nil")
			return
		}

		let transition = SKTransition.doorway(withDuration: 0.75)
//		let transition = SKTransition.crossFade(withDuration: 1)
//		let transition = SKTransition.flipHorizontal(withDuration: 1)
//		let transition = SKTransition.fade(withDuration: 1)
//		let transition = SKTransition.reveal(with: .down, duration: 1)
//		let transition = SKTransition.moveIn(with: .right, duration: 1)
//		let transition = SKTransition.doorsOpenHorizontal(withDuration: 1)
//		let transition = SKTransition.doorsCloseHorizontal(withDuration: 1)


		let newScene = SnakeGameScene.create()
		newScene.initialGameState = gameState
		scene?.view?.presentScene(newScene, transition: transition)
	}

    override func didMove(to view: SKView) {
		super.didMove(to: view)

		if !contentCreated {
			createContent()
			contentCreated = true
		}

		needLayout = true
		needRedraw = true
		needBecomeFirstResponder = true

        #if os(macOS)
		flow_start()
        #endif
	}

	func createContent() {
		let camera = SKCameraNode()
		self.camera = camera
		addChild(camera)

		guard levelSelectorNode.parent == nil else {
			fatalError("Expected levelSelectorNode.parent to be nil, but got non-nil.")
		}
        #if os(macOS)
        levelSelectorNode.selectedIndex = NSUserDefaultsController.shared.selectedLevelIndex
        #else
        levelSelectorNode.selectedIndex = 6
        #endif
        needSendingLevelInfo = true
		levelSelectorNode.createGameStates()
		levelSelectorNode.createGameNodes()
		self.addChild(levelSelectorNode)
    }

	override func willMove(from view: SKView) {
		super.willMove(from: view)
        #if os(macOS)
		flow_stop()
        #endif
	}

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
		if AppConstant.ignoreRepeatingKeyDownEvents && event.isARepeat {
			//log.debug("keyDown: ignoring repeating event.")
			return
		}
        switch event.keyCodeEnum {
        case .enter:
			launchGame()
        case .escape:
            NSApp.terminate(self)
        case .arrowLeft:
			levelSelectorNode.moveSelectionLeft()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
            needSendingLevelInfo = true
        case .arrowRight:
			levelSelectorNode.moveSelectionRight()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
            needSendingLevelInfo = true
        case .arrowDown:
			levelSelectorNode.moveSelectionDown()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
            needSendingLevelInfo = true
        case .arrowUp:
			levelSelectorNode.moveSelectionUp()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
            needSendingLevelInfo = true
        default:
            log.debug("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    #endif

	func updateCamera() {
		let nodeSize: CGSize = self.size
		var scale: CGFloat = 1
		if nodeSize.width >= 1 && nodeSize.height >= 1 {
			let levelSelectorSize: CGSize = self.levelSelectorNode.size
			let xScale: CGFloat = levelSelectorSize.width / nodeSize.width
			let yScale: CGFloat = levelSelectorSize.height / nodeSize.height
			scale = max(xScale, yScale)
		}
		self.camera?.setScale(scale)
	}

	override func didChangeSize(_ oldSize: CGSize) {
		super.didChangeSize(oldSize)
//		log.debug("did change size: \(oldSize) \(size)")
		needLayout = true
	}

    override func update(_ currentTime: TimeInterval) {
		super.update(currentTime)
//		log.debug("update")

		if needBecomeFirstResponder {
			needBecomeFirstResponder = false
            #if os(macOS)
			snake_becomeFirstResponder()
            #endif
		}

		if needRedraw {
			needRedraw = false
			levelSelectorNode.redraw()
		}

		if needLayout {
			needLayout = false
			updateCamera()
		}

        if needSendingLevelInfo {
            needSendingLevelInfo = false
            if let gameState: SnakeGameState = levelSelectorNode.gameStateForSelectedIndex() {
                sendInfoEvent(.showLevelDetail(gameState))
            } else {
                sendInfoEvent(.showLevelSelector)
            }
        }
	}
}

#if os(macOS)
extension SnakeLevelSelectorScene: FlowDispatcher {
	func flow_dispatch(_ event: FlowEvent) {
		if event is FlowEvent_DidChangePlayerSetting {
			log.debug("player settings did change")
			levelSelectorNode.createGameStates()
			levelSelectorNode.createGameNodes()
			needRedraw = true
            needSendingLevelInfo = true
		}
	}
}
#endif
