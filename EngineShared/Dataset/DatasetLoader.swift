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

    internal static func snakeGameEnvironmentReplay(resourceName: String) throws -> SnakeGameEnvironmentReplay {
        do {
            let data: Data = try SnakeDatasetBundle.load(resourceName)
            let model: SnakeDatasetResult = try SnakeDatasetResult(serializedData: data)
            return try DatasetLoader.snakeGameEnvironmentReplay(model: model)
        } catch {
            log.error("Unable to load file: \(error)")
            fatalError()
        }
    }

    internal static func snakeGameEnvironmentReplay(model: SnakeDatasetResult) throws -> SnakeGameEnvironmentReplay {
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

        return SnakeGameEnvironmentReplay(
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
}

extension Array where Element == SnakeDatasetPosition {
    internal func toUIntVec2Array() -> [UIntVec2] {
        self.map { UIntVec2(x: $0.x, y: $0.y) }
    }

    internal func toIntVec2Array() -> [IntVec2] {
        self.map { IntVec2(x: Int32($0.x), y: Int32($0.y)) }
    }
}

