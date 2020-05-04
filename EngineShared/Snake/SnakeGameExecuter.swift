// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftProtobuf

public protocol SnakeGameExecuter: class {
    func reset()
    func undo()
    func executeStep(_ gameState: SnakeGameState) -> SnakeGameState

    /// Decide about optimal path to get to the food.
    func computeNextBotMovement(_ gameState: SnakeGameState) -> SnakeGameState

    func placeNewFood(_ gameState: SnakeGameState) -> SnakeGameState

    func endOfStep(_ gameState: SnakeGameState) -> SnakeGameState
}


/// Replay the moves of a historic game.
public class SnakeGameExecuterReplay: SnakeGameExecuter {
    public let initialGameState: SnakeGameState
    private let foodPositions: [IntVec2]
    private let player1Positions: [IntVec2]
    private let player2Positions: [IntVec2]
    private let player1CauseOfDeath: SnakeCauseOfDeath
    private let player2CauseOfDeath: SnakeCauseOfDeath

    private init(initialGameState: SnakeGameState, foodPositions: [IntVec2], player1Positions: [IntVec2], player2Positions: [IntVec2], player1CauseOfDeath: SnakeCauseOfDeath, player2CauseOfDeath: SnakeCauseOfDeath) {
        self.initialGameState = initialGameState
        self.foodPositions = foodPositions
        self.player1Positions = player1Positions
        self.player2Positions = player2Positions
        self.player1CauseOfDeath = player1CauseOfDeath
        self.player2CauseOfDeath = player2CauseOfDeath
    }

    public static func create() -> SnakeGameExecuterReplay {
        let data: Data = SnakeDatasetBundle.load("2.snakeDataset")
        let model: SnakeDatasetResult
        do {
            model = try SnakeDatasetResult(serializedData: data)
        } catch {
            log.error("Unable to load file: \(error)")
            fatalError()
        }

        guard model.hasLevel else {
            log.error("Expected the file to contain a 'level' snapshot of the board, but got none.")
            fatalError()
        }
        guard model.hasFirstStep else {
            log.error("Expected the file to contain a 'firstStep' snapshot of the board, but got none.")
            fatalError()
        }
        guard model.hasLastStep else {
            log.error("Expected the file to contain a 'lastStep' snapshot of the board, but got none.")
            fatalError()
        }
        log.debug("successfully loaded file")

        let firstStep: SnakeDatasetStep = model.firstStep
        let lastStep: SnakeDatasetStep = model.lastStep

        let levelBuilder: SnakeLevelBuilder
        do {
            levelBuilder = try DatasetLoader.snakeLevelBuilder(levelModel: model.level)
        } catch {
            log.error("Unable to parse level. \(error)")
            fatalError()
        }

        assignFoodPosition(levelBuilder: levelBuilder, stepModel: firstStep)

        var player1: SnakePlayer?
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerA(stepModel: firstStep) {
            if playerResult.isAlive {
                levelBuilder.player1_body = playerResult.snakeBody

                if let role: SnakePlayerRole = SnakePlayerRole.create(uuid: playerResult.uuid) {
                    var player = SnakePlayer.create(id: .player1, role: role)
                    player = player.playerWithNewSnakeBody(playerResult.snakeBody)
                    player1 = player
                }
            }
        }

        var player2: SnakePlayer?
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerB(stepModel: firstStep) {
            if playerResult.isAlive {
                levelBuilder.player2_body = playerResult.snakeBody

                if let role: SnakePlayerRole = SnakePlayerRole.create(uuid: playerResult.uuid) {
                    var player = SnakePlayer.create(id: .player2, role: role)
                    player = player.playerWithNewSnakeBody(playerResult.snakeBody)
                    player2 = player
                }
            }
        }

        // IDEA: When the game ends, show the causeOfDeath in the UI.
        var player1CauseOfDeath: SnakeCauseOfDeath = .other
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerA(stepModel: lastStep) {
            log.debug("last step for player 1. \(playerResult.isAlive) \(playerResult.causeOfDeath)")
            player1CauseOfDeath = playerResult.causeOfDeath
        }
        var player2CauseOfDeath: SnakeCauseOfDeath = .other
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerB(stepModel: lastStep) {
            log.debug("last step for player 2. \(playerResult.isAlive) \(playerResult.causeOfDeath)")
            player2CauseOfDeath = playerResult.causeOfDeath
        }


        let level: SnakeLevel = levelBuilder.level()
        log.debug("level: \(level)")

        // IDEA: check hashes of the loaded level with the level in the file system.

        let foodPositions: [IntVec2] = model.foodPositions.toIntVec2Array()
        let player1Positions: [IntVec2] = model.playerAPositions.toIntVec2Array()
        let player2Positions: [IntVec2] = model.playerBPositions.toIntVec2Array()

        log.debug("level.id: '\(model.level.uuid)'")
        log.debug("food positions.count: \(foodPositions.count)")
        log.debug("player1 positions.count: \(player1Positions.count)")
        log.debug("player2 positions.count: \(player2Positions.count)")

        let pretty = PrettyPrintArray(prefixLength: 10, suffixLength: 2, separator: ",", ellipsis: "...")
        log.debug("player1: \(pretty.format(player1Positions))")
        log.debug("player2: \(pretty.format(player2Positions))")
        log.debug("food: \(pretty.format(foodPositions))")

        if model.hasTimestamp {
            let t: Google_Protobuf_Timestamp = model.timestamp
            let date: Date = t.date
            log.debug("date: \(date)")
        }

        // IDEA: validate positions are inside the level coordinates
        // IDEA: validate that none of the snakes overlap with each other
        // IDEA: validate that the snakes only occupy empty cells
        // IDEA: validate that the food is placed on an empty cell

        guard ValidateDistance.distanceIsOne(player1Positions) else {
            log.error("Invalid player1 positions. All moves must be by a distance of 1 unit.")
            fatalError()
        }
        guard ValidateDistance.distanceIsOne(player2Positions) else {
            log.error("Invalid player2 positions. All moves must be by a distance of 1 unit.")
            fatalError()
        }

        var gameState = SnakeGameState.empty()
        gameState = gameState.stateWithNewLevel(level)

        if let player: SnakePlayer = player1 {
            gameState = gameState.stateWithNewPlayer1(player)
        } else {
            var player = SnakePlayer.create(id: .player1, role: .none)
            player = player.uninstall()
            gameState = gameState.stateWithNewPlayer1(player)
        }

        if let player: SnakePlayer = player2 {
            gameState = gameState.stateWithNewPlayer2(player)
        } else {
            var player = SnakePlayer.create(id: .player2, role: .none)
            player = player.uninstall()
            gameState = gameState.stateWithNewPlayer2(player)
        }

        gameState = gameState.stateWithNewFoodPosition(level.initialFoodPosition.intVec2)

        return SnakeGameExecuterReplay(
            initialGameState: gameState,
            foodPositions: foodPositions,
            player1Positions: player1Positions,
            player2Positions: player2Positions,
            player1CauseOfDeath: player1CauseOfDeath,
            player2CauseOfDeath: player2CauseOfDeath
        )
    }

    static func assignFoodPosition(levelBuilder: SnakeLevelBuilder, stepModel: SnakeDatasetStep) {
        guard case .foodPosition(let foodPositionModel)? = stepModel.optionalFoodPosition else {
            log.error("Expected file to contain a food position for the first step, but got none.")
            fatalError()
        }
        levelBuilder.initialFoodPosition = UIntVec2(x: foodPositionModel.x, y: foodPositionModel.y)
    }

    private static func snakePlayerResultWithPlayerA(stepModel: SnakeDatasetStep) -> DatasetLoader.SnakePlayerResult? {
        guard case .playerA(let player)? = stepModel.optionalPlayerA else {
            log.error("Expected player A, but got none.")
            return nil
        }
        do {
            return try DatasetLoader.snakePlayerResult(playerModel: player)
        } catch {
            log.error("Unable to parse player A. \(error)")
            return nil
        }
    }

    private static func snakePlayerResultWithPlayerB(stepModel: SnakeDatasetStep) -> DatasetLoader.SnakePlayerResult? {
        guard case .playerB(let player)? = stepModel.optionalPlayerB else {
            log.error("Expected player B, but got none.")
            return nil
        }
        do {
            return try DatasetLoader.snakePlayerResult(playerModel: player)
        } catch {
            log.error("Unable to parse player B. \(error)")
            return nil
        }
    }

    public func reset() {
    }

    public func undo() {
    }

    public func executeStep(_ currentGameState: SnakeGameState) -> SnakeGameState {
        var gameState: SnakeGameState = currentGameState
        let newGameState = gameState.detectCollision()
        gameState = newGameState

        if gameState.player1.isInstalledAndAlive {
            var player: SnakePlayer = gameState.player1
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
//            player = stuckSnakeDetector1.killBotIfStuckInLoop(player)
            gameState = gameState.stateWithNewPlayer1(player)
        }

        if gameState.player2.isInstalledAndAlive {
            var player: SnakePlayer = gameState.player2
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
//            player = stuckSnakeDetector2.killBotIfStuckInLoop(player)
            gameState = gameState.stateWithNewPlayer2(player)
        }

        return gameState
    }

    public func computeNextBotMovement(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let currentIteration: UInt64 = oldGameState.numberOfSteps + 2
        var newGameState: SnakeGameState = oldGameState

        if newGameState.player1.isInstalledAndAlive {
            if currentIteration >= player1Positions.count {
                log.debug("Player1 is dead. Reached end of player1Positions array. \(self.player1CauseOfDeath)")
                newGameState = newGameState.killPlayer1(self.player1CauseOfDeath)
            } else {
                let position: IntVec2 = player1Positions[Int(currentIteration)]
                let head: SnakeHead = newGameState.player1.snakeBody.head
                let movement: SnakeBodyMovement = head.moveToward(position) ?? SnakeBodyMovement.dontMove
                //log.debug("move from \(head.position) to \(position)   movement: \(movement)")
                if movement == .dontMove {
                    log.error("Killing player1. The snake is supposed to move, but doesn't. Iteration: \(currentIteration)")
                    newGameState = newGameState.killPlayer1(.killAfterAFewTimeSteps)
                } else {
//                    log.debug("#\(currentIteration) player1: movement \(movement)")
                    newGameState = newGameState.updatePendingMovementForPlayer1(movement)
                }
            }
        }

        if newGameState.player2.isInstalledAndAlive {
            if currentIteration >= player2Positions.count {
                log.debug("Player2 is dead. Reached end of player2Positions array. \(self.player2CauseOfDeath)")
                newGameState = newGameState.killPlayer2(self.player2CauseOfDeath)
            } else {
                let position: IntVec2 = player2Positions[Int(currentIteration)]
                let head: SnakeHead = newGameState.player2.snakeBody.head
                let movement: SnakeBodyMovement = head.moveToward(position) ?? SnakeBodyMovement.dontMove
                //log.debug("move from \(head.position) to \(position)   movement: \(movement)")
                if movement == .dontMove {
                    log.error("Killing player2. The snake is supposed to move, but doesn't. Iteration: \(currentIteration)")
                    newGameState = newGameState.killPlayer2(.killAfterAFewTimeSteps)
                } else {
//                    log.debug("#\(currentIteration) player2: movement \(movement)")
                    newGameState = newGameState.updatePendingMovementForPlayer2(movement)
                }
            }
        }

        return newGameState
    }

    public func placeNewFood(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let currentIteration: UInt64 = oldGameState.numberOfSteps + 1
        guard currentIteration < foodPositions.count else {
            log.debug("Reached end of foodPositions array.  Iteration: \(currentIteration)")
            return oldGameState
        }
        let position: IntVec2 = foodPositions[Int(currentIteration)]
        guard position != oldGameState.foodPosition else {
//            log.debug("#\(currentIteration) food is unchanged. position: \(position)")
            return oldGameState
        }
        log.debug("#\(currentIteration) placing new food at \(position)")
        return oldGameState.stateWithNewFoodPosition(position)
    }

    static let printNumberOfSteps = false

    public func endOfStep(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let step0: UInt64 = oldGameState.numberOfSteps
        let newGameState: SnakeGameState = oldGameState.incrementNumberOfSteps()
        let step1: UInt64 = newGameState.numberOfSteps
        if Self.printNumberOfSteps {
            log.debug("----------- numberOfSteps \(step0) -> \(step1) -----------")
        }
        return newGameState
    }
}


public class SnakeGameExecuterInteractive: SnakeGameExecuter {
    private var stuckSnakeDetector1 = StuckSnakeDetector(humanReadableName: "Player1")
    private var stuckSnakeDetector2 = StuckSnakeDetector(humanReadableName: "Player2")
    private var foodGenerator: SnakeFoodGenerator = SnakeFoodGenerator()

    public init() {}

    public func reset() {
        stuckSnakeDetector1.reset()
        stuckSnakeDetector2.reset()
    }

    public func undo() {
        stuckSnakeDetector1.undo()
        stuckSnakeDetector2.undo()
    }

    public func executeStep(_ currentGameState: SnakeGameState) -> SnakeGameState {
        var gameState: SnakeGameState = currentGameState
        let newGameState = gameState.detectCollision()
        gameState = newGameState

        if gameState.player1.isInstalledAndAlive {
            var player: SnakePlayer = gameState.player1
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
            player = stuckSnakeDetector1.killBotIfStuckInLoop(player)
            gameState = gameState.stateWithNewPlayer1(player)
        }

        if gameState.player2.isInstalledAndAlive {
            var player: SnakePlayer = gameState.player2
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
            player = stuckSnakeDetector2.killBotIfStuckInLoop(player)
            gameState = gameState.stateWithNewPlayer2(player)
        }

        return gameState
    }

	public func computeNextBotMovement(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let oldPlayer1: SnakePlayer = oldGameState.player1
        let oldPlayer2: SnakePlayer = oldGameState.player2

        var computePlayer1 = false
		if case SnakePlayerRole.bot = oldPlayer1.role {
			if oldPlayer1.isInstalledAndAlive && oldPlayer1.pendingMovement == .dontMove {
                computePlayer1 = true
            }
        }
        var computePlayer2 = false
        if case SnakePlayerRole.bot = oldPlayer2.role {
            if oldPlayer2.isInstalledAndAlive && oldPlayer2.pendingMovement == .dontMove {
                computePlayer2 = true
            }
        }

        guard computePlayer1 || computePlayer2 else {
            // No need to compute next movement for the bots.
            return oldGameState
        }
        //log.debug("will compute")

        var newGameState: SnakeGameState = oldGameState
        if computePlayer1 {
            let newBotState = newGameState.player1.bot.compute(
                level: newGameState.level,
                player: newGameState.player1,
                oppositePlayer: newGameState.player2,
                foodPosition: newGameState.foodPosition
            )
            let pendingMovement: SnakeBodyMovement = newBotState.plannedMovement
            newGameState = newGameState.updateBot1(newBotState)
            newGameState = newGameState.updatePendingMovementForPlayer1(pendingMovement)
            //log.debug("player1: \(pendingMovement)")
		}

		if computePlayer2 {
            let newBotState = newGameState.player2.bot.compute(
                level: newGameState.level,
                player: newGameState.player2,
                oppositePlayer: newGameState.player1,
                foodPosition: newGameState.foodPosition
            )
            let pendingMovement: SnakeBodyMovement = newBotState.plannedMovement
            newGameState = newGameState.updateBot2(newBotState)
            newGameState = newGameState.updatePendingMovementForPlayer2(pendingMovement)
            //log.debug("player2: \(pendingMovement)")
		}

        //log.debug("did compute")
		return newGameState
	}

    public func placeNewFood(_ oldGameState: SnakeGameState) -> SnakeGameState {
        if oldGameState.foodPosition != nil {
            return oldGameState
        }
        // IDEA: Generate CSV file with statistics about food eating frequency
        //let steps: UInt64 = self.gameState.numberOfSteps
        //log.debug("place new food: \(steps)")
        return foodGenerator.placeNewFood(oldGameState)
    }

    static let printNumberOfSteps = false

    public func endOfStep(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let step0: UInt64 = oldGameState.numberOfSteps
        let newGameState: SnakeGameState = oldGameState.incrementNumberOfSteps()
        let step1: UInt64 = newGameState.numberOfSteps
        if Self.printNumberOfSteps {
            log.debug("----------- numberOfSteps \(step0) -> \(step1) -----------")
        }
        return newGameState
    }
}

extension SnakeGameState {

	/// Deal with collision when one player or both players are installed.
    /// Do nothing when no players are installed.
	fileprivate func detectCollision() -> SnakeGameState {
        let player1_installedAndAlive: Bool = self.player1.isInstalledAndAlive
        let player2_installedAndAlive: Bool = self.player2.isInstalledAndAlive

        guard player1_installedAndAlive || player2_installedAndAlive else {
			log.debug("Both players are dead. No need to check for collision between them. 1")
			return self
		}
        var gameState: SnakeGameState = self

		let detector = SnakeCollisionDetector.create(
			level: gameState.level,
			foodPosition: gameState.foodPosition,
			player1: gameState.player1,
			player2: gameState.player2
		)
		detector.process()

		if player1_installedAndAlive && detector.player1Alive == false {
            let collisionType: SnakeCollisionType = detector.collisionType1
            log.info("killing player1 because: \(collisionType)")
            gameState = gameState.killPlayer1(collisionType.causeOfDeath)
		}
		if player2_installedAndAlive && detector.player2Alive == false {
            let collisionType: SnakeCollisionType = detector.collisionType2
            log.info("killing player2 because: \(collisionType)")
			gameState = gameState.killPlayer2(collisionType.causeOfDeath)
		}

		if detector.player1EatsFood {
			gameState = gameState.stateWithNewFoodPosition(nil)
			var player: SnakePlayer = gameState.player1
			player = player.updatePendingAct(.eat)
			gameState = gameState.stateWithNewPlayer1(player)
		}
		if detector.player2EatsFood {
			gameState = gameState.stateWithNewFoodPosition(nil)
			var player: SnakePlayer = gameState.player2
			player = player.updatePendingAct(.eat)
			gameState = gameState.stateWithNewPlayer2(player)
		}
		return gameState
	}
}

extension SnakeCollisionType {
    /// Convert from a `CollisionType` to its corresponding `CauseOfDeath`.
    fileprivate var causeOfDeath: SnakeCauseOfDeath {
        switch self {
        case .noCollision:
            fatalError("Inconsistency. A collision happened, but no collision is registered. Should never happen!")
        case .snakeCollisionWithWall:
            return .collisionWithWall
        case .snakeCollisionWithOpponent:
            return .collisionWithOpponent
        case .snakeCollisionWithItself:
            return .collisionWithItself
        }
    }
}

extension StuckSnakeDetector {
    /// While playing as a human, I find it annoying to get killed because
    /// I'm doing the same patterns over and over.
    /// So this "stuck in loop" detection only applies to bots.
    fileprivate func killBotIfStuckInLoop(_ player: SnakePlayer) -> SnakePlayer {
        guard player.isInstalledAndAlive && player.isBot else {
            return player
        }
        self.append(player.snakeBody)
        if self.isStuck {
            return player.kill(.stuckInALoop)
        } else {
            return player
        }
    }
}
