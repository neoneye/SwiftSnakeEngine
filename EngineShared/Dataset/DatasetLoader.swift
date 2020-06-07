// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftProtobuf

public class DatasetLoader {
    enum DatasetLoaderError: Error {
        case runtimeError(message: String)
    }

    internal static func snakeLevelBuilder(levelModel: SnakeDatasetLevel) throws -> SnakeLevelBuilder {
        let uuidString: String = levelModel.uuid
        guard let uuid: UUID = UUID(uuidString: uuidString) else {
            throw DatasetLoaderError.runtimeError(message: "Expected a valid uuid, but got: '\(uuidString)'")
        }
        guard levelModel.width >= 3 && levelModel.height >= 3 else {
            throw DatasetLoaderError.runtimeError(message: "Expected size of level to be 3 or more, but got less. Cannot create level.")
        }
        let size = UIntVec2(x: levelModel.width, y: levelModel.height)
        let emptyPositions: [UIntVec2] = levelModel.emptyPositions.toUIntVec2Array()
        let emptyPositionSet = Set<UIntVec2>(emptyPositions)
        let builder = SnakeLevelBuilder(id: uuid, size: size)

        // Install walls on the non-empty positions
        for y: UInt32 in 0..<size.y {
            for x: UInt32 in 0..<size.x {
                let position = UIntVec2(x: x, y: y)
                let isEmpty: Bool = emptyPositionSet.contains(position)
                if !isEmpty {
                    builder.installWall(at: position)
                }
            }
        }
        return builder
    }

    internal struct SnakePlayerResult {
        let uuid: UUID
        let isAlive: Bool
        let causeOfDeath: SnakeCauseOfDeath
        let snakeBody: SnakeBody
    }

    internal static func snakePlayerResult(playerModel: SnakeDatasetPlayer) throws -> SnakePlayerResult {
        guard let uuid: UUID = UUID(uuidString: playerModel.uuid) else {
            throw DatasetLoaderError.runtimeError(message: "Invalid UUID for the player role")
        }
        let positions: [IntVec2] = playerModel.bodyPositions.toIntVec2Array()
        let snakeBody: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: positions.reversed())

        let datasetCauseOfDeath: SnakeDatasetCauseOfDeath = playerModel.causeOfDeath
        let causeOfDeath: SnakeCauseOfDeath
        switch datasetCauseOfDeath {
        case .other:
            causeOfDeath = .other
        case .collisionWithWall:
            causeOfDeath = .collisionWithWall
        case .collisionWithItself:
            causeOfDeath = .collisionWithItself
        case .collisionWithOpponent:
            causeOfDeath = .collisionWithOpponent
        case .stuckInLoop:
            causeOfDeath = .stuckInALoop
        default:
            causeOfDeath = .other
        }
        return SnakePlayerResult(
            uuid: uuid,
            isAlive: playerModel.alive,
            causeOfDeath: causeOfDeath,
            snakeBody: snakeBody
        )
    }

    internal static func snakeGameEnvironmentReplay(resourceName: String, verbose: Bool) throws -> GameEnvironmentReplay {
        let data: Data = try SnakeDatasetBundle.load(resourceName)
        return try DatasetLoader.snakeGameEnvironmentReplay(data: data, verbose: verbose)
    }

    internal static func snakeGameEnvironmentReplay(data: Data, verbose: Bool) throws -> GameEnvironmentReplay {
        let model: SnakeDatasetResult = try SnakeDatasetResult(serializedData: data)
        return try DatasetLoader.snakeGameEnvironmentReplay(model: model, verbose: verbose)
    }

    internal static func snakeGameEnvironmentReplay(model: SnakeDatasetResult, verbose: Bool) throws -> GameEnvironmentReplay {
        guard model.hasLevel else {
            throw DatasetLoaderError.runtimeError(message: "Expected the file to contain a 'level' snapshot of the board, but got none.")
        }
        guard model.hasFirstStep else {
            throw DatasetLoaderError.runtimeError(message: "Expected the file to contain a 'firstStep' snapshot of the board, but got none.")
        }
        guard model.hasLastStep else {
            throw DatasetLoaderError.runtimeError(message: "Expected the file to contain a 'lastStep' snapshot of the board, but got none.")
        }

        let firstStep: SnakeDatasetStep = model.firstStep
        let lastStep: SnakeDatasetStep = model.lastStep

        let foodPositions: [IntVec2] = model.foodPositions.toIntVec2Array()
        let player1Positions: [IntVec2] = model.playerAPositions.toIntVec2Array()
        let player2Positions: [IntVec2] = model.playerBPositions.toIntVec2Array()

        let levelBuilder: SnakeLevelBuilder = try DatasetLoader.snakeLevelBuilder(levelModel: model.level)
        guard let initialFoodPosition: UIntVec2 = foodPositions.first?.uintVec2() else {
            throw DatasetLoaderError.runtimeError(message: "Expected the file to contain one or more foodPositions, but got none.")
        }
        levelBuilder.initialFoodPosition = initialFoodPosition

        // Obtain player1 body positions.
        var player1: SnakePlayer?
        if let playerResult: DatasetLoader.SnakePlayerResult = try firstStep.snakePlayerResultWithPlayerA() {
            if playerResult.isAlive {
                levelBuilder.player1_body = playerResult.snakeBody

                if let role: SnakePlayerRole = SnakePlayerRole.create(uuid: playerResult.uuid) {
                    var player = SnakePlayer.create(id: .player1, role: role)
                    player = player.playerWithNewSnakeBody(playerResult.snakeBody)
                    player1 = player
                }
            }
        }

        // Obtain player2 body positions.
        var player2: SnakePlayer?
        if let playerResult: DatasetLoader.SnakePlayerResult = try firstStep.snakePlayerResultWithPlayerB() {
            if playerResult.isAlive {
                levelBuilder.player2_body = playerResult.snakeBody

                if let role: SnakePlayerRole = SnakePlayerRole.create(uuid: playerResult.uuid) {
                    var player = SnakePlayer.create(id: .player2, role: role)
                    player = player.playerWithNewSnakeBody(playerResult.snakeBody)
                    player2 = player
                }
            }
        }

        // Obtain the cause of death for each player.
        // If the player is alive, then use `nil` as magic value.
        var player1CauseOfDeath: SnakeCauseOfDeath? = nil
        if let playerResult: DatasetLoader.SnakePlayerResult = try lastStep.snakePlayerResultWithPlayerA() {
            if verbose {
                log.debug("last step for player 1. \(playerResult.isAlive) \(playerResult.causeOfDeath)")
            }
            if !playerResult.isAlive {
                player1CauseOfDeath = playerResult.causeOfDeath
            }
        }
        var player2CauseOfDeath: SnakeCauseOfDeath? = nil
        if let playerResult: DatasetLoader.SnakePlayerResult = try lastStep.snakePlayerResultWithPlayerB() {
            if verbose {
                log.debug("last step for player 2. \(playerResult.isAlive) \(playerResult.causeOfDeath)")
            }
            if !playerResult.isAlive {
                player2CauseOfDeath = playerResult.causeOfDeath
            }
        }

        let level: SnakeLevel = levelBuilder.level()
        if verbose {
            log.debug("level: \(level)")
            log.debug("level.id: '\(model.level.uuid)'")
            log.debug("food positions.count: \(foodPositions.count)")
            log.debug("player1 positions.count: \(player1Positions.count)")
            log.debug("player2 positions.count: \(player2Positions.count)")

            let pretty = PrettyPrintArray(prefixLength: 10, suffixLength: 2, separator: ",", ellipsis: "...")
            log.debug("player1: \(pretty.format(player1Positions))")
            log.debug("player2: \(pretty.format(player2Positions))")
            log.debug("food: \(pretty.format(foodPositions))")
        }

        // Extract the timestamp of when this dataset was created.
        let datasetTimestamp: Date
        if model.hasTimestamp {
            let t: Google_Protobuf_Timestamp = model.timestamp
            datasetTimestamp = t.date
        } else {
            datasetTimestamp = Date.distantPast
        }

        // IDEA: check hashes of the loaded level corresponds with the level files in the file system.
        // IDEA: validate positions are inside the level coordinates
        // IDEA: validate that none of the snakes overlap with each other
        // IDEA: validate that the snakes only occupy empty cells
        // IDEA: validate that the food is placed on an empty cell
        // IDEA: use unsigned integers for positions, that never can be negative. Less error handling.

        // Ensure that there is no cheating.
        // The snake can only move by 1 unit for each step.
        // It's not allowed for the snake to jump more than 1 unit.
        // It's not allowed for the snake to stand still and move by less than 1 unit.
        guard ValidateDistance.distanceIsOne(player1Positions) else {
            throw DatasetLoaderError.runtimeError(message: "Invalid player1 positions. All moves must be by a distance of 1 unit.")
        }
        guard ValidateDistance.distanceIsOne(player2Positions) else {
            throw DatasetLoaderError.runtimeError(message: "Invalid player2 positions. All moves must be by a distance of 1 unit.")
        }

        // Create the initial game state with its initial configuration.
        var gameState = SnakeGameState.empty()
        gameState = gameState.stateWithNewLevel(level)

        // Install player 1, if there is data for this player.
        if let player: SnakePlayer = player1 {
            gameState = gameState.stateWithNewPlayer1(player)
        } else {
            var player = SnakePlayer.create(id: .player1, role: .none)
            player = player.uninstall()
            gameState = gameState.stateWithNewPlayer1(player)
        }

        // Install player 2, if there is data for this player.
        if let player: SnakePlayer = player2 {
            gameState = gameState.stateWithNewPlayer2(player)
        } else {
            var player = SnakePlayer.create(id: .player2, role: .none)
            player = player.uninstall()
            gameState = gameState.stateWithNewPlayer2(player)
        }

        // Place the initial food.
        gameState = gameState.stateWithNewFoodPosition(level.initialFoodPosition.intVec2)

        return GameEnvironmentReplay(
            datasetTimestamp: datasetTimestamp,
            initialGameState: gameState,
            foodPositions: foodPositions,
            player1Positions: player1Positions,
            player2Positions: player2Positions,
            player1CauseOfDeath: player1CauseOfDeath,
            player2CauseOfDeath: player2CauseOfDeath
        )
    }

}

extension SnakeDatasetStep {
    fileprivate func snakePlayerResultWithPlayerA() throws -> DatasetLoader.SnakePlayerResult? {
        guard case .playerA(let player)? = self.optionalPlayerA else {
            return nil
        }
        do {
            return try DatasetLoader.snakePlayerResult(playerModel: player)
        } catch {
            throw DatasetLoader.DatasetLoaderError.runtimeError(message: "Unable to parse player A. \(error)")
        }
    }

    fileprivate func snakePlayerResultWithPlayerB() throws -> DatasetLoader.SnakePlayerResult? {
        guard case .playerB(let player)? = self.optionalPlayerB else {
            return nil
        }
        do {
            return try DatasetLoader.snakePlayerResult(playerModel: player)
        } catch {
            throw DatasetLoader.DatasetLoaderError.runtimeError(message: "Unable to parse player B. \(error)")
        }
    }
}

extension Array where Element == SnakeDatasetPosition {
    internal func toUIntVec2Array() -> [UIntVec2] {
        self.map { UIntVec2(x: $0.x, y: $0.y) }
    }

    internal func toIntVec2Array() -> [IntVec2] {
        self.map { IntVec2(x: Int32($0.x), y: Int32($0.y)) }
    }
}

