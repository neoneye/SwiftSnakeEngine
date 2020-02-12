// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame
import SSEventFlow

enum UpdateAction {
	case stepForwardContinuously
	case stepForwardOnce
	case stepBackwardOnce
}

class SnakeGameScene: SKScene {
	var contentCreated = false
	var needRedraw = false
	var needLayout = false
	var needBecomeFirstResponder = false
	var shouldPauseAfterUpdate = false
	var updateAction = UpdateAction.stepForwardContinuously

	var trainingSessionUUID: UUID
	var initialGameState: SnakeGameState
	var gameState: SnakeGameState
	var gameNode: SnakeGameNode
	var previousGameStates: [SnakeGameState] = []
	let sound_snakeDies = SKAction.playSoundFileNamed("snake_dies.wav", waitForCompletion: false)
	let sound_snakeEats = SKAction.playSoundFileNamed("snake_eats.wav", waitForCompletion: false)
	let sound_snakeStep = SKAction.playSoundFileNamed("snake_step.wav", waitForCompletion: false)

	class func create() -> SnakeGameScene {
		let scene = SnakeGameScene(size: CGSize(width: 100, height: 100))
		scene.scaleMode = .resizeFill
		return scene
	}

	class func createBotsVsBots() -> SnakeGameScene {
		let newScene = SnakeGameScene.create()
		let snakeBotType: SnakeBot.Type = SnakeBotFactory.snakeBotTypes.first ?? SnakeBotFactory.emptyBotType()
		newScene.initialGameState = SnakeGameState.create(
			player1: .bot(snakeBotType: snakeBotType),
			player2: .none,
			levelName: "Level 7.csv"
		)
		return newScene
	}

	override init(size: CGSize) {
		self.trainingSessionUUID = UUID()
		self.initialGameState = SnakeGameScene.defaultInitialGameState()
		self.gameState = SnakeGameState.empty()
		self.gameNode = SnakeGameNode()
		super.init(size: size)
	}

	required init?(coder aDecoder: NSCoder) {
		self.trainingSessionUUID = UUID()
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
		//print("restartGame")
		updateAction = .stepForwardContinuously
		isPaused = false
		needRedraw = true
		needLayout = true
		previousGameStates = []
		gameState = initialGameState
		trainingSessionUUID = UUID()
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
			//print("keyDown: ignoring repeating event.")
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
			gameState.saveTrainingData(trainingSessionUUID: self.trainingSessionUUID)
		case .enter:
			restartGame()
		case .tab:
			restartGame()
		case .spacebar:
			if gameState.player1.isAlive || gameState.player2.isAlive {
				isPaused = !isPaused
				updateAction = .stepForwardContinuously
			} else {
				restartGame()
			}
		case .escape:
			exit(EXIT_SUCCESS)
		case .arrowUp:
			userInputForPlayer1(.arrowUp)
		case .arrowLeft:
			userInputForPlayer1(.arrowLeft)
		case .arrowRight:
			userInputForPlayer1(.arrowRight)
		case .arrowDown:
			userInputForPlayer1(.arrowDown)
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }

	func userInputForPlayer1(_ userInput: SnakeUserInput) {
		guard gameState.player1.isAlive && gameState.player1.role == .human else {
			return
		}
		let movement: SnakeBodyMovement = userInput.newMovement(oldDirection: gameState.player1.snakeBody.head.direction)
		let newGameState: SnakeGameState = gameState.updatePendingMovementForPlayer1(movement)
		self.gameState = newGameState
		self.needRedraw = true
		self.isPaused = false
		self.updateAction = .stepForwardContinuously
	}

	func userInputForPlayer2(_ userInput: SnakeUserInput) {
		guard gameState.player2.isAlive && gameState.player2.role == .human else {
			return
		}
		let movement: SnakeBodyMovement = userInput.newMovement(oldDirection: gameState.player2.snakeBody.head.direction)
		let newGameState: SnakeGameState = gameState.updatePendingMovementForPlayer2(movement)
		self.gameState = newGameState
		self.needRedraw = true
		self.isPaused = false
		self.updateAction = .stepForwardContinuously
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
		//print("place new food: \(steps)")
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
//		print("did change size: \(oldSize) \(size)")
		needLayout = true
	}

    override func update(_ currentTime: TimeInterval) {
		super.update(currentTime)
//		print("update")

		switch updateAction {
		case .stepForwardContinuously:
			stepForward()
		case .stepForwardOnce:
			stepForward()
		case .stepBackwardOnce:
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

		if shouldPauseAfterUpdate {
			shouldPauseAfterUpdate = false
			isPaused = true
			//print("pausing game after update")
		}
	}

	func stepForward() {
		let newGameState0 = SnakeGameExecuter.prepareBotMovements(gameState)
		let newGameState1 = SnakeGameExecuter.preventHumanCollisions(newGameState0)
		self.gameState = newGameState1

		let isWaiting = SnakeGameExecuter.isWaitingForHumanInput(self.gameState)
		if isWaiting {
			//print("waiting for players")
			return
		}

		let oldGameState: SnakeGameState = self.gameState
		//print("all the players have made their decision")
		do {
			let state: SnakeGameState = self.gameState
//			print("appending: \(state.player2.debugDescription)")
			previousGameStates.append(state)
		}

		if AppConstant.killPlayer2AfterAFewSteps {
			if gameState.player2.isAlive && gameState.numberOfSteps == 10 {
				var player: SnakePlayer = gameState.player2
				player = player.killed()
				gameState = gameState.stateWithNewPlayer2(player)
			}
		}

		let newGameState2 = SnakeGameExecuter.executeStep(gameState)
		gameState = newGameState2

		needRedraw = true

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

		if gameState.player1.isDead && gameState.player2.isDead {
			self.isPaused = true
			return
		}

		placeNewFood()

		if AppConstant.saveTrainingData {
			oldGameState.saveTrainingData(trainingSessionUUID: self.trainingSessionUUID)
		}
    }

	func stepBackward() {
		guard var state: SnakeGameState = previousGameStates.popLast() else {
			print("Canot step backward. There is no previous state to rewind back to.")
			return
		}
		state = state.clearPendingMovementAndPendingLengthForHumanPlayers()
//		print("rewind to: \(state.player2.debugDescription)")
		gameState = state
		needRedraw = true
	}

	func schedule_stepBackwardOnce() {
		updateAction = .stepBackwardOnce
		isPaused = false
		shouldPauseAfterUpdate = true
	}

	func schedule_stepForwardOnce() {
		updateAction = .stepForwardOnce
		isPaused = false
		shouldPauseAfterUpdate = true
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
