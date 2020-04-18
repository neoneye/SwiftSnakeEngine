// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import Combine
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

class LevelSelectorScene: SKScene {
    var cancellable = Set<AnyCancellable>()
	var contentCreated = false
	var needRedraw = false
	var needLayout = false
	var needBecomeFirstResponder = false
    var needSendingLevelInfo = true
    var insetTop: CGFloat = 0

	var levelSelectorNode: SnakeLevelSelectorNode

	class func create() -> LevelSelectorScene {
        let scene = LevelSelectorScene()
		return scene
	}

    override init() {
		self.levelSelectorNode = SnakeLevelSelectorNode.create()
		super.init(size: CGSize.zero)
        self.scaleMode = .resizeFill
        self.backgroundColor = AppColor.levelSelector_background.skColor
	}

	required init?(coder aDecoder: NSCoder) {
        fatalError()
	}

    /// Tells you when the scene is presented by a view.
    override func didMove(to view: SKView) {
        guard let skView: SnakeGameSKView = view as? SnakeGameSKView else {
            fatalError("Expected view to be of type SnakeGameSKView. Cannot subscribe to events.")
        }

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

        #if os(iOS)
        // Used while the level selector is visible.
        // Here the user can enable/disable playing against a bot.
        skView.model.$levelSelector_humanVsBot
            .sink { [weak self] (value: Bool) in
                log.debug("human vs bot. value: \(value)")
                let playerMode: PlayerMode
                if value {
                    playerMode = .twoPlayer_humanBot
                } else {
                    playerMode = .singlePlayer_human
                }
                PlayerModeController().set(playerMode)
                self?.didChangePlayerSettings()
            }
            .store(in: &cancellable)

        // Used while the level selector is visible.
        // This is whenever the user adjust font sizes.
        // Or the user changes the orientation of the device.
        skView.model.$levelSelector_insetTop
            .sink { [weak self] (value: CGFloat) in
                log.debug("insetTop. value: \(value)")
                self?.insetTop = value
                self?.needRedraw = true
            }
            .store(in: &cancellable)
        #endif

        skView.model.levelSelector_visible = true
    }

    /// Tells you when the scene is about to be removed from a view
    override func willMove(from view: SKView) {
        super.willMove(from: view)

        #if os(macOS)
        flow_stop()
        #endif

        cancellable.removeAll()
    }

    func createContent() {
        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)

        guard levelSelectorNode.parent == nil else {
            fatalError("Expected levelSelectorNode.parent to be nil, but got non-nil.")
        }
        levelSelectorNode.selectedIndex = SelectedLevelController().value
        needSendingLevelInfo = true
        levelSelectorNode.createGameStates()
        levelSelectorNode.createGameNodes()
        self.addChild(levelSelectorNode)
    }

    #if os(macOS)
	override func mouseUp(with event: NSEvent) {
        let mousePosition: CGPoint = event.location(in: self)
        tapOnItem(at: mousePosition)
	}
    #endif

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = touches.first else {
            return
        }
        let touchPoint: CGPoint = touch.location(in: self)
        tapOnItem(at: touchPoint)
    }
    #endif

    private func tapOnItem(at point: CGPoint) {
        let currentSelectedIndex: Int? = self.levelSelectorNode.selectedIndex
        var newSelectedIndex: Int = -1

        let nodes: [SKNode] = self.nodes(at: point)
        for node in nodes {
            // IDEA: It's confusing that I'm using `SnakeGameNode`.
            // Make a `SnakeLevelSelectorItemNode`, that contains the `SnakeGameNode`,
            // so that inspecting the nodes will have a meaningful type.
            guard let n = node as? SnakeGameNode else {
                //log.debug("tap on unknown node: \(type(of: node))")
                continue
            }
            let name: String = n.name ?? "unnamed node"
            log.debug("tap on SnakeGameNode.  '\(name)'")
            let parts: Array<Substring> = name.split(separator: " ")
            guard let lastPart: Substring = parts.last else {
                log.error("Expected the SnakeGameNode name to have an uint suffix, but got none. name: '\(name)'")
                continue
            }
            guard let i = Int(lastPart) else {
                log.error("Expected the SnakeGameNode name to have an uint suffix, but it's garbage. name: '\(name)'")
                continue
            }
            newSelectedIndex = i
        }

        guard newSelectedIndex >= 0 else {
            return
        }
        if currentSelectedIndex != newSelectedIndex {
            self.levelSelectorNode.selectedIndex = newSelectedIndex
            didChangeSelectedLevelIndex(newSelectedIndex)
        } else {
            launchGame()
        }
    }

    private func didChangeSelectedLevelIndex(_ selectedIndex: Int) {
        // Remember the current selected index, so the UI next time shows the same selected item.
        SelectedLevelController().set(levelSelectorNode.selectedIndex ?? 0)
        needRedraw = true
        needSendingLevelInfo = true
    }

	private func launchGame() {
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
            didChangeSelectedLevelIndex(levelSelectorNode.selectedIndex ?? 0)
        case .arrowRight:
			levelSelectorNode.moveSelectionRight()
            didChangeSelectedLevelIndex(levelSelectorNode.selectedIndex ?? 0)
        case .arrowDown:
			levelSelectorNode.moveSelectionDown()
            didChangeSelectedLevelIndex(levelSelectorNode.selectedIndex ?? 0)
        case .arrowUp:
			levelSelectorNode.moveSelectionUp()
            didChangeSelectedLevelIndex(levelSelectorNode.selectedIndex ?? 0)
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
            levelSelectorNode.redraw(insetTop: self.insetTop)
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

    func didChangePlayerSettings() {
        log.debug("player settings did change")
        levelSelectorNode.createGameStates()
        levelSelectorNode.createGameNodes()
        needRedraw = true
        needSendingLevelInfo = true
    }
}

#if os(macOS)
extension LevelSelectorScene: FlowDispatcher {
	func flow_dispatch(_ event: FlowEvent) {
		if event is FlowEvent_DidChangePlayerSetting {
            didChangePlayerSettings()
		}
	}
}
#endif
