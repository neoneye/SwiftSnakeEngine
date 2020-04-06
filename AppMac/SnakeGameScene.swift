// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame
import SSEventFlow

enum UpdateAction {
    case doNothing
	case stepForwardContinuously
	case stepForwardOnce
	case stepBackwardOnce

    static var initialUpdateAction: UpdateAction {
        switch AppConstant.gameInitialStepMode {
        case .production_stepForwardContinuously:
            return .stepForwardContinuously
        case .doNothing:
            return .doNothing
        }
    }
}

class SnakeGameScene: SKScene {
	var contentCreated = false
    var gameNodeNeedRedraw: GameNodeNeedRedraw = []
	var needLayout = false
	var needBecomeFirstResponder = false
	var pendingUpdateAction = UpdateAction.initialUpdateAction
    var needSendingBeginNewGame = true

	var trainingSessionUUID: UUID
	var trainingSessionURLs: [URL]
	var initialGameState: SnakeGameState
	var gameState: SnakeGameState
	var gameNode: SnakeGameNode
    var gameExecuter = SnakeGameExecuter()
	var previousGameStates: [SnakeGameState] = []
	let sound_snakeDies = SKAction.playSoundFileNamed("snake_dies.wav", waitForCompletion: false)
	let sound_snakeEats = SKAction.playSoundFileNamed("snake_eats.wav", waitForCompletion: false)
	let sound_snakeStep = SKAction.playSoundFileNamed("snake_step.wav", waitForCompletion: false)

	class func create() -> SnakeGameScene {
		let scene = SnakeGameScene(size: CGSize(width: 100, height: 100))
		scene.scaleMode = .resizeFill
		return scene
	}

	class func createBotVsNone() -> SnakeGameScene {
		let newScene = SnakeGameScene.create()
		let snakeBotType: SnakeBot.Type = SnakeBotFactory.snakeBotTypes.last ?? SnakeBotFactory.emptyBotType()
		newScene.initialGameState = SnakeGameState.create(
			player1: .bot(snakeBotType: snakeBotType),
			player2: .none,
			levelName: "Level 0.csv"
		)
		return newScene
	}

	override init(size: CGSize) {
		self.trainingSessionUUID = UUID()
		self.trainingSessionURLs = []
		self.initialGameState = SnakeGameScene.defaultInitialGameState()
		self.gameState = SnakeGameState.empty()
		self.gameNode = SnakeGameNode()
        self.gameNodeNeedRedraw.insert(.newGame)
		super.init(size: size)
	}

	required init?(coder aDecoder: NSCoder) {
		self.trainingSessionUUID = UUID()
		self.trainingSessionURLs = []
		self.initialGameState = SnakeGameScene.defaultInitialGameState()
		self.gameState = SnakeGameState.empty()
		self.gameNode = SnakeGameNode()
        self.gameNodeNeedRedraw.insert(.newGame)
		super.init(coder: aDecoder)
	}

	override func mouseUp(with event: NSEvent) {
		let transition = SKTransition.doorway(withDuration: 0.75)
//		let transition = SKTransition.crossFade(withDuration: 1)
//		let transition = SKTransition.flipHorizontal(withDuration: 1)
//		let transition = SKTransition.fade(withDuration: 1)
//		let transition = SKTransition.reveal(with: .down, duration: 1)
//		let transition = SKTransition.moveIn(with: .right, duration: 1)
//		let transition = SKTransition.doorsOpenHorizontal(withDuration: 1)
//		let transition = SKTransition.doorsCloseHorizontal(withDuration: 1)

		let newScene = SnakeLevelSelectorScene.create()
		scene?.view?.presentScene(newScene, transition: transition)
	}

    /// Workaround, similar to the function `mouseMoved()`.
    ///
    /// I'm using SwiftUI, so I guess that is the reason that the function `mouseMoved()` never get called.
    /// I had to make a work around for where I'm listening for mouse moved.
    func trackingNSHostingView_mouseMoved(with event: NSEvent) {
        let mousePosition: CGPoint = event.location(in: self.gameNode)
        let gridPosition: CGPoint = gridPointFromGameNodeLocation(mousePosition)
        log.debug("grid position: \(gridPosition.string1)")
    }

    override func didMove(to view: SKView) {
		super.didMove(to: view)

		if !contentCreated {
			createContent()
			contentCreated = true
		}

		needLayout = true
        gameNodeNeedRedraw.insert(.didMoveToView)
		needBecomeFirstResponder = true

		flow_start()
	}

	func createContent() {
		let camera = SKCameraNode()
		self.camera = camera
		addChild(camera)

		gameNode.configure()
		self.addChild(gameNode)

		restartGame()
    }
	
	override func willMove(from view: SKView) {
		super.willMove(from: view)
		flow_stop()
	}

	func restartGame() {
		//log.debug("restartGame")
		pendingUpdateAction = UpdateAction.initialUpdateAction
		isPaused = false
        gameNodeNeedRedraw.insert(.newGame)
		needLayout = true
        needSendingBeginNewGame = true
		previousGameStates = []
		gameState = initialGameState
		trainingSessionUUID = UUID()
		trainingSessionURLs = []
        gameExecuter.reset()
		placeNewFood()
	}

	class func defaultInitialGameState() -> SnakeGameState {
		let snakeBotType: SnakeBot.Type = SnakeBotFactory.snakeBotTypes.first ?? SnakeBotFactory.emptyBotType()
		return SnakeGameState.create(
			player1: .human,
			player2: .bot(snakeBotType: snakeBotType),
			levelName: SnakeLevelManager.shared.defaultLevelName
		)
	}

    override func keyDown(with event: NSEvent) {
		if AppConstant.ignoreRepeatingKeyDownEvents && event.isARepeat {
			//log.debug("keyDown: ignoring repeating event.")
			return
		}
        switch event.keyCodeEnum {
		case .letterW:
			userInputForPlayer2(.arrowUp)
		case .letterA:
			userInputForPlayer2(.arrowLeft)
		case .letterS:
			userInputForPlayer2(.arrowDown)
		case .letterD:
			userInputForPlayer2(.arrowRight)
		case .letterZ:
			schedule_stepBackwardOnce()
		case .letterT:
			let url: URL = gameState.saveTrainingData(trainingSessionUUID: self.trainingSessionUUID)
			trainingSessionURLs.append(url)
		case .enter:
			restartGame()
		case .tab:
			restartGame()
		case .spacebar:
			if gameState.player1.isAlive || gameState.player2.isAlive {
                let updateAction = self.pendingUpdateAction
                switch updateAction {
                case .doNothing:
                    self.pendingUpdateAction = .stepForwardContinuously
                case .stepForwardContinuously, .stepForwardOnce, .stepBackwardOnce:
                    self.pendingUpdateAction = .doNothing
                }
			} else {
				restartGame()
			}
		case .escape:
            NSApp.terminate(self)
		case .arrowUp:
			userInputForPlayer1(.arrowUp)
		case .arrowLeft:
			userInputForPlayer1(.arrowLeft)
		case .arrowRight:
			userInputForPlayer1(.arrowRight)
		case .arrowDown:
			userInputForPlayer1(.arrowDown)
        default:
            log.debug("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }

	func userInputForPlayer1(_ userInput: SnakeUserInput) {
		guard gameState.player1.isAlive && gameState.player1.role == .human else {
			return
		}
		let movement: SnakeBodyMovement = userInput.newMovement(oldDirection: gameState.player1.snakeBody.head.direction)
        guard movement != SnakeBodyMovement.dontMove else {
            return
        }
		let newGameState: SnakeGameState = gameState.updatePendingMovementForPlayer1(movement)
		self.gameState = newGameState
        self.gameNodeNeedRedraw.insert(.userInputForPlayer)
		self.isPaused = false
		self.pendingUpdateAction = .stepForwardContinuously
	}

	func userInputForPlayer2(_ userInput: SnakeUserInput) {
		guard gameState.player2.isAlive && gameState.player2.role == .human else {
			return
		}
		let movement: SnakeBodyMovement = userInput.newMovement(oldDirection: gameState.player2.snakeBody.head.direction)
        guard movement != SnakeBodyMovement.dontMove else {
            return
        }
		let newGameState: SnakeGameState = gameState.updatePendingMovementForPlayer2(movement)
		self.gameState = newGameState
        self.gameNodeNeedRedraw.insert(.userInputForPlayer)
		self.isPaused = false
		self.pendingUpdateAction = .stepForwardContinuously
	}

	lazy var foodGenerator: SnakeFoodGenerator = {
		return SnakeFoodGenerator()
	}()

	func placeNewFood() {
		if self.gameState.foodPosition != nil {
			return
		}
		// IDEA: Generate CSV file with statistics about food eating frequency
		//let steps: UInt64 = self.gameState.numberOfSteps
		//log.debug("place new food: \(steps)")
		self.gameState = foodGenerator.placeNewFood(self.gameState)
        self.gameNodeNeedRedraw.insert(.newFood)
	}

	func updateCamera() {
		let levelSize: UIntVec2 = gameState.level.size
		let gridSize: CGFloat = AppConstant.tileSize
		let levelWidth = CGFloat(levelSize.x) * gridSize
		let levelHeight = CGFloat(levelSize.y) * gridSize
		let nodeSize: CGSize = self.size
		let xScale: CGFloat = levelWidth / nodeSize.width
		let yScale: CGFloat = levelHeight / nodeSize.height
		let scale: CGFloat = max(xScale, yScale)
		self.camera?.setScale(scale)
	}

	override func didChangeSize(_ oldSize: CGSize) {
		super.didChangeSize(oldSize)
//		log.debug("did change size: \(oldSize) \(size)")
		needLayout = true
	}

    override func update(_ currentTime: TimeInterval) {
		super.update(currentTime)

        if gameNodeNeedRedraw.contains(.newGame) {
            let (newGameState, didChange) = self.gameState.computeNextBotMovement()
            if didChange {
                self.gameState = newGameState
                self.gameNodeNeedRedraw.insert(.computeNextBotMovement)
            }
        }

        let updateAction = self.pendingUpdateAction
        switch updateAction {
        case .doNothing:
            self.pendingUpdateAction = .doNothing
        case .stepForwardContinuously:
            self.pendingUpdateAction = .stepForwardContinuously
            stepForward()
        case .stepForwardOnce:
            self.pendingUpdateAction = .doNothing
            stepForward()
        case .stepBackwardOnce:
            self.pendingUpdateAction = .doNothing
            stepBackward()
        }

		if needBecomeFirstResponder {
			needBecomeFirstResponder = false
			snake_becomeFirstResponder()
		}

        if !gameNodeNeedRedraw.isEmpty {
            log.debug("redraw: \(gameNodeNeedRedraw)")
            gameNodeNeedRedraw = []
            gameNode.gameState = self.gameState
            gameNode.redraw()
        }

		if needLayout {
			needLayout = false
			updateCamera()
		}

        if needSendingBeginNewGame {
            needSendingBeginNewGame = false
            sendInfoEvent(.beginNewGame(self.gameState))
        }
	}

	func stepForward() {
        self.gameState = self.gameState.preventHumanCollisions()

		let isWaiting = self.gameState.isWaitingForHumanInput()
		if isWaiting {
			//log.debug("waiting for players")
			return
		}

		let oldGameState: SnakeGameState = self.gameState
		//log.debug("all the players have made their decision")
		do {
			let state: SnakeGameState = self.gameState
//			log.debug("appending: \(state.player2.debugDescription)")
			previousGameStates.append(state)
		}

		if AppConstant.killPlayer2AfterAFewSteps {
			if gameState.player2.isAlive && gameState.numberOfSteps == 10 {
				var player: SnakePlayer = gameState.player2
                player = player.kill(.killAfterAFewTimeSteps)
				gameState = gameState.stateWithNewPlayer2(player)
			}
		}

		let newGameState2 = gameExecuter.executeStep(gameState)
		gameState = newGameState2

        gameNodeNeedRedraw.insert(.stepForward)

        do {
            let oldLength: UInt = oldGameState.player1.snakeBody.length
            let newLength: UInt = self.gameState.player1.snakeBody.length
            if oldLength != newLength {
                sendInfoEvent(.player1_didUpdateLength(newLength))
            }
        }

        do {
            let oldLength: UInt = oldGameState.player2.snakeBody.length
            let newLength: UInt = self.gameState.player2.snakeBody.length
            if oldLength != newLength {
                sendInfoEvent(.player2_didUpdateLength(newLength))
            }
        }

		if oldGameState.foodPosition != self.gameState.foodPosition {
			if let pos: IntVec2 = oldGameState.foodPosition {
				let point = cgPointFromGridPoint(pos)
				explode(at: point, for: 0.25, zPosition: 200) {}
				playSoundEffect(sound_snakeEats)
			}
		}

        do {
            let (newGameState, didChange) = self.gameState.computeNextBotMovement()
            if didChange {
                self.gameState = newGameState
                self.gameNodeNeedRedraw.insert(.computeNextBotMovement)
            }
        }

		let human1Alive: Bool = gameState.player1.role == .human && gameState.player1.isAlive
		let human2Alive: Bool = gameState.player2.role == .human && gameState.player2.isAlive
		if human1Alive || human2Alive {
			playSoundEffect(sound_snakeStep)
		}
		
		let player1Dies: Bool = oldGameState.player1.isAlive && self.gameState.player1.isDead
		let player2Dies: Bool = oldGameState.player2.isAlive && self.gameState.player2.isDead
		if player1Dies || player2Dies {
			playSoundEffect(sound_snakeDies)
		}
        if player1Dies {
            sendInfoEvent(.player1_killed(self.gameState.player1.killEvents))
        }
        if player2Dies {
            sendInfoEvent(.player2_killed(self.gameState.player2.killEvents))
        }

		if gameState.player1.isDead && gameState.player2.isDead {
			self.isPaused = true
			// IDEA: Determine the winner: the longest snake, or the longest lived snake, or a combo?
			// IDEA: pass on which player won/loose.
			PostProcessTrainingData.process(trainingSessionUUID: self.trainingSessionUUID, urls: self.trainingSessionURLs)
			return
		}

		placeNewFood()

		if AppConstant.saveTrainingData {
			let url: URL = oldGameState.saveTrainingData(trainingSessionUUID: self.trainingSessionUUID)
			trainingSessionURLs.append(url)
		}
    }

	func stepBackward() {
		guard var state: SnakeGameState = previousGameStates.popLast() else {
            log.info("Canot step backward. There is no previous state to rewind back to.")
			return
		}
        gameExecuter.undo()
		state = state.clearPendingMovementAndPendingLengthForHumanPlayers()
//		log.debug("rewind to: \(state.player2.debugDescription)")
		gameState = state
        gameNodeNeedRedraw.insert(.stepBackward)
	}

	func schedule_stepBackwardOnce() {
		pendingUpdateAction = .stepBackwardOnce
        isPaused = false
	}

	func schedule_stepForwardOnce() {
		pendingUpdateAction = .stepForwardOnce
        isPaused = false
	}

	func playSoundEffect(_ action: SKAction) {
		guard NSUserDefaultsController.shared.isSoundEffectsEnabled else {
			return
		}
		run(action)
	}

	func cgPointFromGridPoint(_ point: IntVec2) -> CGPoint {
		let gridSize: CGFloat = AppConstant.tileSize
		let midx: CGFloat = CGFloat(gameState.level.size.x) / 2
		let midy: CGFloat = CGFloat(gameState.level.size.y) / 2
		let px: CGFloat = CGFloat(point.x) + 0.5
		let py: CGFloat = CGFloat(point.y) + 0.5
		return CGPoint(x: (px - midx) * gridSize, y: (py - midy) * gridSize)
	}

    func gridPointFromGameNodeLocation(_ point: CGPoint) -> CGPoint {
        let gridSize: CGFloat = AppConstant.tileSize
        let midx: CGFloat = CGFloat(gameState.level.size.x) / 2
        let midy: CGFloat = CGFloat(gameState.level.size.y) / 2
        return CGPoint(x: (point.x / gridSize) + midx, y: (point.y / gridSize) + midy)
    }
}

extension SnakeGameScene: FlowDispatcher {
	func flow_dispatch(_ event: FlowEvent) {
		if event is FlowEvent_PerformUndo {
			schedule_stepBackwardOnce()
		}
		if event is FlowEvent_PerformRedo {
			schedule_stepForwardOnce()
		}
        if let e = event as? FlowEvent_TrackingNSHostingView_MouseMoved {
            self.trackingNSHostingView_mouseMoved(with: e.nsEvent)
        }
	}
}

struct GameNodeNeedRedraw: OptionSet {
    let rawValue: UInt
    static let didMoveToView          = GameNodeNeedRedraw(rawValue: 1 << 0)
    static let newGame                = GameNodeNeedRedraw(rawValue: 1 << 1)
    static let plannedPath            = GameNodeNeedRedraw(rawValue: 1 << 2)
    static let userInputForPlayer     = GameNodeNeedRedraw(rawValue: 1 << 3)
    static let newFood                = GameNodeNeedRedraw(rawValue: 1 << 4)
    static let computeNextBotMovement = GameNodeNeedRedraw(rawValue: 1 << 5)
    static let stepForward            = GameNodeNeedRedraw(rawValue: 1 << 6)
    static let stepBackward           = GameNodeNeedRedraw(rawValue: 1 << 7)
}

extension GameNodeNeedRedraw: CustomStringConvertible, CustomDebugStringConvertible {
    private static var debugDescriptions: [(Self, String)] = [
        (.didMoveToView, "didMoveToView"),
        (.newGame, "newGame"),
        (.plannedPath, "plannedPath"),
        (.userInputForPlayer, "userInputForPlayer"),
        (.newFood, "newFood"),
        (.computeNextBotMovement, "computeNextBotMovement"),
        (.stepForward, "stepForward"),
        (.stepBackward, "stepBackward")
    ]

    var debugDescription: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        return "GameNodeNeedRedraw(rawValue: \(self.rawValue)) \(result)"
    }

    var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        if result.isEmpty {
            return "None"
        } else {
            return result.joined(separator: ",")
        }
    }
}

