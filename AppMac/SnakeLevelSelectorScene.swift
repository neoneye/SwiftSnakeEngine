// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame
import SSEventFlow

class SnakeLevelSelectorScene: SKScene {
	var contentCreated = false
	var needRedraw = false
	var needLayout = false
	var needBecomeFirstResponder = false

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

	override func mouseUp(with event: NSEvent) {
		launchGame()
	}

	func launchGame() {
		guard let gameState: SnakeGameState = levelSelectorNode.gameStateForSelectedIndex() else {
			print("ERROR: Expected gameStateForSelectedIndex() to be non-nil, but got nil")
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

		flow_start()
	}

	func createContent() {
		let camera = SKCameraNode()
		self.camera = camera
		addChild(camera)

		guard levelSelectorNode.parent == nil else {
			fatalError("Expected levelSelectorNode.parent to be nil, but got non-nil.")
		}
		levelSelectorNode.selectedIndex = NSUserDefaultsController.shared.selectedLevelIndex
		levelSelectorNode.createGameStates()
		levelSelectorNode.createGameNodes()
		self.addChild(levelSelectorNode)
    }

	override func willMove(from view: SKView) {
		super.willMove(from: view)
		flow_stop()
	}

    override func keyDown(with event: NSEvent) {
		if AppConstant.ignoreRepeatingKeyDownEvents && event.isARepeat {
			//print("keyDown: ignoring repeating event.")
			return
		}
        switch event.keyCode {
		case 36: // Enter
			launchGame()
		case 53: // ESCape
			exit(EXIT_SUCCESS)
		case 123: // Arrow Left
			levelSelectorNode.moveSelectionLeft()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
		case 124: // Arrow Right
			levelSelectorNode.moveSelectionRight()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
		case 125: // Arrow Down
			levelSelectorNode.moveSelectionDown()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
		case 126: // Arrow Up
			levelSelectorNode.moveSelectionUp()
			NSUserDefaultsController.shared.selectedLevelIndex = levelSelectorNode.selectedIndex ?? 0
			needRedraw = true
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }

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
//		print("did change size: \(oldSize) \(size)")
		needLayout = true
	}

    override func update(_ currentTime: TimeInterval) {
		super.update(currentTime)
//		print("update")

		if needBecomeFirstResponder {
			needBecomeFirstResponder = false
			snake_becomeFirstResponder()
		}

		if needRedraw {
			needRedraw = false
			levelSelectorNode.redraw()
		}

		if needLayout {
			needLayout = false
			updateCamera()
		}
	}
}

extension SnakeLevelSelectorScene: FlowDispatcher {
	func flow_dispatch(_ event: FlowEvent) {
		if event is FlowEvent_DidChangePlayerSetting {
			print("player settings did change")
			levelSelectorNode.createGameStates()
			levelSelectorNode.createGameNodes()
			needRedraw = true
		}
	}
}
