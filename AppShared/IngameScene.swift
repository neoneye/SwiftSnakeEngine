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

class IngameScene: SKScene {
    var cancellable = Set<AnyCancellable>()
	var contentCreated = false
    var gameNodeNeedRedraw: GameNodeNeedRedraw = []
	var needLayout = false
	var needBecomeFirstResponder = false
	var pendingUpdateAction = UpdateAction.initialUpdateAction
    var needSendingBeginNewGame = true

	var trainingSessionUUID: UUID
	var trainingSessionURLs: [URL]
	private let initialGameState: SnakeGameState
	var gameState: SnakeGameState
	var gameNode: SnakeGameNode
    var gameExecuter: SnakeGameExecuter = SnakeGameExecuterFactory.create()
	var previousGameStates: [SnakeGameState] = []
	let sound_snakeDies = SKAction.playSoundFileNamed("snake_dies.wav", waitForCompletion: false)
	let sound_snakeEats = SKAction.playSoundFileNamed("snake_eats.wav", waitForCompletion: false)
	let sound_snakeStep = SKAction.playSoundFileNamed("snake_step.wav", waitForCompletion: false)

	class func createHumanVsNone() -> IngameScene {
		let gameState = SnakeGameState.create(
			player1: .human,
			player2: .none,
			levelName: "Level 0.csv"
		)
        return IngameScene(initialGameState: gameState)
	}

    class func createBotVsNone() -> IngameScene {
        let snakeBotType: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let gameState = SnakeGameState.create(
            player1: .bot(snakeBotType: snakeBotType),
            player2: .none,
            levelName: "Level 0.csv"
        )
        return IngameScene(initialGameState: gameState)
    }

    init(initialGameState: SnakeGameState) {
        self.trainingSessionUUID = UUID()
        self.trainingSessionURLs = []
        self.initialGameState = initialGameState
        self.gameState = initialGameState
        self.gameNode = SnakeGameNode()
        self.gameNodeNeedRedraw.insert(.newGame)
        super.init(size: CGSize(width: 100, height: 100))
        self.scaleMode = .resizeFill
    }

    override init() {
        fatalError()
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

        createContent()
        gameNodeNeedRedraw.insert(.didMoveToView)
        restartGame()

        #if os(macOS)
        flow_start()
        #endif

        // Rebuild the UI whenever there are changes to Display light/dark appearance.
        skView.model.userInterfaceStyle
            .sink { [weak self] in
                log.debug("userInterfaceStyle did change")
                self?.contentCreated = false
                self?.createContent()
                self?.gameNodeNeedRedraw.insert(.userInterfaceStyle)
            }
            .store(in: &cancellable)

        #if os(iOS)
        tapGestureRecognizer.addTarget(self, action: #selector(tapAction(sender:)))
        self.view?.addGestureRecognizer(tapGestureRecognizer)
        #endif

        skView.model.levelSelector_visible = false
    }

    /// Tells you when the scene is about to be removed from a view
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        cancellable.removeAll()

        #if os(macOS)
        flow_stop()
        #endif

        #if os(iOS)
        self.view?.removeGestureRecognizer(tapGestureRecognizer)
        #endif
    }

    func createContent() {
        if contentCreated {
            return
        }
        contentCreated = true

        self.removeAllChildren()

        self.backgroundColor = AppColor.ingame_background.skColor

        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)

        gameNode.configure()
        self.addChild(gameNode)

        needLayout = true
        needBecomeFirstResponder = true
    }


    #if os(iOS)

    let tapGestureRecognizer = UITapGestureRecognizer()

    @objc func tapAction(sender: UITapGestureRecognizer) {
        userInputForPlayer1Forward()
    }

    var touchBeganAtPosition: CGPoint = CGPoint.zero

    enum TouchMoveDirection {
        case undecided
        case horizontal
        case vertical
    }

    var touchMoveDirection = TouchMoveDirection.undecided


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch: UITouch = touches.first else {
            return
        }

        let touchPoint: CGPoint = touch.location(in: self)
        touchBeganAtPosition = touchPoint
        touchMoveDirection = TouchMoveDirection.undecided
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = touches.first else {
            return
        }

        let touchPoint: CGPoint = touch.location(in: self)
        switch self.touchMoveDirection {
        case .undecided:
            touchMoved_undecided(beganAtPosition: self.touchBeganAtPosition, currentPosition: touchPoint)
        case .horizontal:
            touchMoved_horizontal(beganAtPosition: self.touchBeganAtPosition, currentPosition: touchPoint)
        case .vertical:
            touchMoved_vertical(beganAtPosition: self.touchBeganAtPosition, currentPosition: touchPoint)
        }
    }

    func touchMoved_undecided(beganAtPosition: CGPoint, currentPosition: CGPoint) {
        let gridPoint0: CGPoint = gridPointFromGameNodeLocation(beganAtPosition)
        let gridPoint1: CGPoint = gridPointFromGameNodeLocation(currentPosition)
        let dx: CGFloat = gridPoint0.x - gridPoint1.x
        let dy: CGFloat = gridPoint0.y - gridPoint1.y
        let dx2: CGFloat = dx * dx
        let dy2: CGFloat = dy * dy
        let distance: CGFloat = sqrt(dx2 + dy2)
        guard distance > 0.1 else {
            return
        }
//        log.debug("undecided distance: \(distance.string2)")
        if dx2 > dy2 {
            touchMoveDirection = .horizontal
//            log.debug("moving horizontal")
        } else {
            touchMoveDirection = .vertical
//            log.debug("moving vertical")
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = touches.first else {
            return
        }

        let touchPoint: CGPoint = touch.location(in: self)
        switch self.touchMoveDirection {
        case .undecided:
            log.debug("do nothing")
        case .horizontal:
            touchUp_horizontal(beganAtPosition: self.touchBeganAtPosition, currentPosition: touchPoint)
        case .vertical:
            touchUp_vertical(beganAtPosition: self.touchBeganAtPosition, currentPosition: touchPoint)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = touches.first else {
            return
        }

        let touchPoint: CGPoint = touch.location(in: self)
        switch self.touchMoveDirection {
        case .undecided:
            log.debug("do nothing")
        case .horizontal:
            touchUp_horizontal(beganAtPosition: self.touchBeganAtPosition, currentPosition: touchPoint)
        case .vertical:
            touchUp_vertical(beganAtPosition: self.touchBeganAtPosition, currentPosition: touchPoint)
        }
    }

    func touchMoved_horizontal(beganAtPosition: CGPoint, currentPosition: CGPoint) {
        guard gameState.player1.isAlive && gameState.player1.role == .human else {
            return
        }
        let snakeHead: SnakeHead = gameState.player1.snakeBody.head

        let gridPoint0: CGPoint = gridPointFromGameNodeLocation(beganAtPosition)
        let gridPoint1: CGPoint = gridPointFromGameNodeLocation(currentPosition)
        var dx: CGFloat = gridPoint1.x - gridPoint0.x
        if dx > 1 {
            dx = 1
        }
        if dx < -1 {
            dx = -1
        }
        var gridPoint2: CGPoint = snakeHead.position.cgPoint
        gridPoint2.x += dx
        gridPoint2.x += 0.5
        gridPoint2.y += 0.5
        self.gameNode.nextMoveIndicatorNode.position = cgPointFromGridPoint2(gridPoint2)
        self.gameNode.nextMoveIndicatorNode.run(SKAction.fadeIn(withDuration: 0.1))
    }

    func touchMoved_vertical(beganAtPosition: CGPoint, currentPosition: CGPoint) {
        guard gameState.player1.isAlive && gameState.player1.role == .human else {
            return
        }
        let snakeHead: SnakeHead = gameState.player1.snakeBody.head

        let gridPoint0: CGPoint = gridPointFromGameNodeLocation(beganAtPosition)
        let gridPoint1: CGPoint = gridPointFromGameNodeLocation(currentPosition)
        var dy: CGFloat = gridPoint1.y - gridPoint0.y
        if dy > 1 {
            dy = 1
        }
        if dy < -1 {
            dy = -1
        }
        var gridPoint2: CGPoint = snakeHead.position.cgPoint
        gridPoint2.y += dy
        gridPoint2.x += 0.5
        gridPoint2.y += 0.5
        self.gameNode.nextMoveIndicatorNode.position = cgPointFromGridPoint2(gridPoint2)
        self.gameNode.nextMoveIndicatorNode.run(SKAction.fadeIn(withDuration: 0.1))
    }

    func touchUp_horizontal(beganAtPosition: CGPoint, currentPosition: CGPoint) {
        let gridPoint0: CGPoint = gridPointFromGameNodeLocation(beganAtPosition)
        let gridPoint1: CGPoint = gridPointFromGameNodeLocation(currentPosition)
        let dx: CGFloat = gridPoint0.x - gridPoint1.x
        let dx2: CGFloat = dx * dx
        let distance: CGFloat = sqrt(dx2)
        guard distance > 0.1 else {
            return
        }

        if dx > 0 {
            userInputForPlayer1(.left)
        }
        if dx < 0 {
            userInputForPlayer1(.right)
        }

        touchUp_snapIntoPlace()
    }

    func touchUp_vertical(beganAtPosition: CGPoint, currentPosition: CGPoint) {
        let gridPoint0: CGPoint = gridPointFromGameNodeLocation(beganAtPosition)
        let gridPoint1: CGPoint = gridPointFromGameNodeLocation(currentPosition)
        let dy: CGFloat = gridPoint0.y - gridPoint1.y
        let dy2: CGFloat = dy * dy
        let distance: CGFloat = sqrt(dy2)
        guard distance > 0.1 else {
            return
        }

        if dy > 0 {
            userInputForPlayer1(.down)
        }
        if dy < 0 {
            userInputForPlayer1(.up)
        }
        touchUp_snapIntoPlace()
    }

    func touchUp_snapIntoPlace() {
        let snakeHead0: SnakeHead = gameState.player1.snakeBody.head
        let snakeHead1: SnakeHead = snakeHead0.simulateTick(movement: gameState.player1.pendingMovement)
        var snakeHeadPosition: CGPoint = snakeHead1.position.cgPoint
        snakeHeadPosition.x += 0.5
        snakeHeadPosition.y += 0.5
        let nodePosition = cgPointFromGridPoint2(snakeHeadPosition)

        let actionSequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.fadeOut(withDuration: 0.15)
        ])
        let actionGroup = SKAction.group([
            SKAction.move(to: nodePosition, duration: 0.05),
            actionSequence
        ])
        self.gameNode.nextMoveIndicatorNode.run(actionGroup)
    }
    #endif

    #if os(macOS)
	override func mouseUp(with event: NSEvent) {
        guard let skView: SnakeGameSKView = self.view as? SnakeGameSKView else {
            log.error("Expected self.view to be of type SnakeGameSKView.")
            return
        }
        skView.model.jumpToLevelSelector.send()
	}
    #endif

    #if os(macOS)
    /// Workaround, similar to the function `mouseMoved()`.
    ///
    /// I'm using SwiftUI, so I guess that is the reason that the function `mouseMoved()` never get called.
    /// I had to make a work around for where I'm listening for mouse moved.
    func gameNSView_mouseMoved(with event: NSEvent) {
        let mousePosition: CGPoint = event.location(in: self.gameNode)
        let gridPosition: CGPoint = gridPointFromGameNodeLocation(mousePosition)
        log.debug("grid position: \(gridPosition.string1)")
    }
    #endif

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
        gameState = gameExecuter.placeNewFood(gameState)
	}

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
		if AppConstant.ignoreRepeatingKeyDownEvents && event.isARepeat {
			//log.debug("keyDown: ignoring repeating event.")
			return
		}
        switch event.keyCodeEnum {
		case .letterW:
			userInputForPlayer2(.up)
		case .letterA:
			userInputForPlayer2(.left)
		case .letterS:
			userInputForPlayer2(.down)
		case .letterD:
			userInputForPlayer2(.right)
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
			userInputForPlayer1(.up)
		case .arrowLeft:
			userInputForPlayer1(.left)
		case .arrowRight:
			userInputForPlayer1(.right)
		case .arrowDown:
			userInputForPlayer1(.down)
        default:
            log.debug("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    #endif

    func userInputForPlayer1Forward() {
        guard gameState.player1.isAlive && gameState.player1.role == .human else {
            return
        }
        let newGameState: SnakeGameState = gameState.updatePendingMovementForPlayer1(.moveForward)
        self.gameState = newGameState
        self.isPaused = false
        self.pendingUpdateAction = .stepForwardContinuously
    }

    func userInputForPlayer1(_ desiredHeadDirection: SnakeHeadDirection) {
        userInputForPlayer(player: gameState.player1, desiredHeadDirection: desiredHeadDirection)
    }

    func userInputForPlayer2(_ desiredHeadDirection: SnakeHeadDirection) {
        userInputForPlayer(player: gameState.player2, desiredHeadDirection: desiredHeadDirection)
    }

    private func userInputForPlayer(player: SnakePlayer, desiredHeadDirection: SnakeHeadDirection) {
        guard player.isAlive && player.role == .human else {
            return
        }
        let dx: Int32
        let dy: Int32
        switch desiredHeadDirection {
        case .up:
            (dx, dy) = (0, 1)
        case .down:
            (dx, dy) = (0, -1)
        case .left:
            (dx, dy) = (-1, 0)
        case .right:
            (dx, dy) = (1, 0)
        }
        let head: SnakeHead = player.snakeBody.head
        let newPosition: IntVec2 = head.position.offsetBy(dx: dx, dy: dy)
        let movement: SnakeBodyMovement = head.moveToward(newPosition) ?? SnakeBodyMovement.dontMove
        guard movement != SnakeBodyMovement.dontMove else {
            userInput_stepBackwardOnce_ifSingleHuman()
            return
        }
        let newGameState: SnakeGameState
        switch player.id {
        case .player1:
            newGameState = gameState.updatePendingMovementForPlayer1(movement)
        case .player2:
            newGameState = gameState.updatePendingMovementForPlayer2(movement)
        }
        self.gameState = newGameState
        self.isPaused = false
        self.pendingUpdateAction = .stepForwardContinuously
    }

    func userInput_stepBackwardOnce_ifSingleHuman() {
        var numberOfHumans: UInt = 0
        if gameState.player1.isInstalled && gameState.player1.role == .human {
            numberOfHumans += 1
        }
        if gameState.player2.isInstalled && gameState.player2.role == .human {
            numberOfHumans += 1
        }
        guard numberOfHumans > 0 else {
            log.debug("In a game without human players, it makes no sense to perform undo")
            return
        }
        guard numberOfHumans < 2 else {
            log.debug("In a game with multiple human players. Then both players have to agree when to undo, and use the undo key for it.")
            return
        }
        schedule_stepBackwardOnce()
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
            self.gameState = self.gameExecuter.computeNextBotMovement(gameState)
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
            #if os(macOS)
			snake_becomeFirstResponder()
            #endif
		}

        if !gameNodeNeedRedraw.isEmpty {
            //log.debug("redraw: \(gameNodeNeedRedraw)")
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

		let isWaiting = self.gameState.isWaitingForInput()
		if isWaiting {
			//log.debug("waiting for input")
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

        self.gameState = self.gameExecuter.computeNextBotMovement(gameState)

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

        self.gameState = gameExecuter.placeNewFood(self.gameState)

		if AppConstant.saveTrainingData {
			let url: URL = oldGameState.saveTrainingData(trainingSessionUUID: self.trainingSessionUUID)
			trainingSessionURLs.append(url)
		}

        self.gameState = self.gameExecuter.endOfStep(self.gameState)
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
        #if os(macOS)
		guard NSUserDefaultsController.shared.isSoundEffectsEnabled else {
			return
		}
        #elseif os(iOS)
        guard SoundEffectController().value else {
            return
        }
        #endif
        run(action)
	}

	func cgPointFromGridPoint(_ point: IntVec2) -> CGPoint {
        let cgPoint = CGPoint(
            x: CGFloat(point.x) + 0.5,
            y: CGFloat(point.y) + 0.5
        )
        return cgPointFromGridPoint2(cgPoint)
	}

    func cgPointFromGridPoint2(_ point: CGPoint) -> CGPoint {
        let gridSize: CGFloat = AppConstant.tileSize
        let midx: CGFloat = CGFloat(gameState.level.size.x) / 2
        let midy: CGFloat = CGFloat(gameState.level.size.y) / 2
        return CGPoint(x: (point.x - midx) * gridSize, y: (point.y - midy) * gridSize)
    }

    func gridPointFromGameNodeLocation(_ point: CGPoint) -> CGPoint {
        let gridSize: CGFloat = AppConstant.tileSize
        let midx: CGFloat = CGFloat(gameState.level.size.x) / 2
        let midy: CGFloat = CGFloat(gameState.level.size.y) / 2
        return CGPoint(x: (point.x / gridSize) + midx, y: (point.y / gridSize) + midy)
    }
}

#if os(macOS)
extension IngameScene: FlowDispatcher {
	func flow_dispatch(_ event: FlowEvent) {
		if event is FlowEvent_PerformUndo {
			schedule_stepBackwardOnce()
		}
		if event is FlowEvent_PerformRedo {
			schedule_stepForwardOnce()
		}
        if let e = event as? FlowEvent_GameNSView_MouseMoved {
            self.gameNSView_mouseMoved(with: e.nsEvent)
        }
	}
}
#endif

struct GameNodeNeedRedraw: OptionSet {
    let rawValue: UInt
    static let didMoveToView          = GameNodeNeedRedraw(rawValue: 1 << 0)
    static let newGame                = GameNodeNeedRedraw(rawValue: 1 << 1)
    static let stepForward            = GameNodeNeedRedraw(rawValue: 1 << 2)
    static let stepBackward           = GameNodeNeedRedraw(rawValue: 1 << 3)
    static let userInterfaceStyle     = GameNodeNeedRedraw(rawValue: 1 << 4)
}

extension GameNodeNeedRedraw: CustomStringConvertible, CustomDebugStringConvertible {
    private static var debugDescriptions: [(Self, String)] = [
        (.didMoveToView, "didMoveToView"),
        (.newGame, "newGame"),
        (.stepForward, "stepForward"),
        (.stepBackward, "stepBackward"),
        (.userInterfaceStyle, "userInterfaceStyle")
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

