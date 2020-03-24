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
	var needRedraw = false
	var needLayout = false
	var needBecomeFirstResponder = false
	var pendingUpdateAction = UpdateAction.initialUpdateAction
    var needSendingBeginNewGame = true
    var readyForComputingBotMovement = false

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
		super.init(size: size)
	}

	required init?(coder aDecoder: NSCoder) {
		self.trainingSessionUUID = UUID()
		self.trainingSessionURLs = []
		self.initialGameState = SnakeGameScene.defaultInitialGameState()
		self.gameState = SnakeGameState.empty()
		self.gameNode = SnakeGameNode()
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
        readyForComputingBotMovement = false
		needRedraw = true
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
		self.needRedraw = true
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
		self.needRedraw = true
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
		needRedraw = true
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

//        log.debug("update \(currentTime)")

        let updateAction = self.pendingUpdateAction
        switch updateAction {
        case .doNothing:
            self.pendingUpdateAction = .doNothing
        case .stepForwardContinuously:
            self.pendingUpdateAction = .stepForwardContinuously
            readyForComputingBotMovement = true
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

		if needRedraw {
			needRedraw = false

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
        // Optimization thoughts:
        //
        // Scenario A: human interaction, then computation of the next bot movement.
        // When a human singlesteps with a bot,
        // then the info written to the logfile must correspond with the things happening on the screen.
        // In this scenario the bots have to be computed AFTER the user have interacted.
        // Terrible UX for the human player.
        // Good UX for the developer.
        //
        // Scenario B: precomputation of the next bot movement, then wait for human interaction.
        // When a human plays against a bot.
        // It can take a long time for a bot to compute a movement.
        // Meanwhile the bot is computing the human can think about what move to make.
        // When the human interacts with the keyboard, we already have the bot movement.
        // So the human will not have to wait for the bot.
        // However this also complicate things. It's difficult to single step through this code.
        // Good UX for the human player.
        // Terrible UX for the developer.
        let precomputeBotMovements: Bool = (AppConstant.gameInitialStepMode == .production_stepForwardContinuously)
        let newGameState0: SnakeGameState
        if precomputeBotMovements || readyForComputingBotMovement {
            readyForComputingBotMovement = false
            newGameState0 = self.gameState.prepareBotMovements()
        } else {
            newGameState0 = self.gameState
        }

        let newGameState1 = newGameState0.preventHumanCollisions()
		self.gameState = newGameState1

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

		needRedraw = true

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
		needRedraw = true
	}

	func schedule_stepBackwardOnce() {
		pendingUpdateAction = .stepBackwardOnce
        isPaused = false
	}

	func schedule_stepForwardOnce() {
		pendingUpdateAction = .stepForwardOnce
        isPaused = false
        readyForComputingBotMovement = true
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
}

extension SnakeGameScene: FlowDispatcher {
	func flow_dispatch(_ event: FlowEvent) {
		if event is FlowEvent_PerformUndo {
			schedule_stepBackwardOnce()
		}
		if event is FlowEvent_PerformRedo {
			schedule_stepForwardOnce()
		}
	}
}
