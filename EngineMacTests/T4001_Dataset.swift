// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

/// These tests verifies that a full serialization/deserialization roundtrip works.
/// 1st step: convert from a model representation to a protobuf representation.
/// 2nd step: convert back to a model representation.
/// 3rd step: verify that the desired model data has been preserved.
class T4001_Dataset: XCTestCase {

    // MARK: -
    func createSnakePlayer_human() -> SnakePlayer {
        let positions: [IntVec2] = [
            IntVec2(x: 10, y: 10),
            IntVec2(x: 11, y: 10),
            IntVec2(x: 12, y: 10),
            IntVec2(x: 12, y:  9),
            IntVec2(x: 12, y:  8),
        ]
        guard let body: SnakeBody = SnakeBody.create(positions: positions) else {
            fatalError("This is supposed to always result in a valid snake")
        }
        var player: SnakePlayer = SnakePlayer.create(id: .player1, role: .human)
        player = player.playerWithNewSnakeBody(body)
        return player
    }

    func test100_serializationRoundtrip_player_human_alive() throws {
        let originalPlayer: SnakePlayer = createSnakePlayer_human()
        let protobufRepresentation: SnakeDatasetPlayer = originalPlayer.toSnakeDatasetPlayer()

        let result: DatasetLoader.SnakePlayerResult = try DatasetLoader.snakePlayerResult(playerModel: protobufRepresentation)

        // Things that are preserved from the original player
        XCTAssertTrue(result.isAlive)
        XCTAssertEqual(result.causeOfDeath, SnakeCauseOfDeath.other)
        XCTAssertEqual(result.uuid, SnakePlayerRole.human.id)
        XCTAssertEqual(result.snakeBody, originalPlayer.snakeBody)
    }

    func test101_serializationRoundtrip_player_human_dead() throws {
        let originalPlayer: SnakePlayer = createSnakePlayer_human().kill(.collisionWithWall)

        let protobufRepresentation: SnakeDatasetPlayer = originalPlayer.toSnakeDatasetPlayer()

        let result: DatasetLoader.SnakePlayerResult = try DatasetLoader.snakePlayerResult(playerModel: protobufRepresentation)

        // Things that are preserved from the original player
        XCTAssertFalse(result.isAlive)
        XCTAssertEqual(result.causeOfDeath, SnakeCauseOfDeath.collisionWithWall)
        XCTAssertEqual(result.uuid, SnakePlayerRole.human.id)
        XCTAssertEqual(result.snakeBody, originalPlayer.snakeBody)
    }

    func createSnakePlayer_bot() -> SnakePlayer {
        let positions: [IntVec2] = [
            IntVec2(x: 10, y:  8),
            IntVec2(x: 10, y:  9),
            IntVec2(x: 10, y: 10),
            IntVec2(x:  9, y: 10)
        ]
        guard let body: SnakeBody = SnakeBody.create(positions: positions) else {
            fatalError("This is supposed to always result in a valid snake")
        }
        let botType: SnakeBot.Type = SnakeBot_MoveForward.self
        var player: SnakePlayer = SnakePlayer.create(id: .player1, role: .bot(snakeBotType: botType))
        player = player.playerWithNewSnakeBody(body)
        return player
    }

    func test102_serializationRoundtrip_player_bot_alive() throws {
        let originalPlayer: SnakePlayer = createSnakePlayer_bot()
        let protobufRepresentation: SnakeDatasetPlayer = originalPlayer.toSnakeDatasetPlayer()

        let result: DatasetLoader.SnakePlayerResult = try DatasetLoader.snakePlayerResult(playerModel: protobufRepresentation)

        // Things that are preserved from the original player
        XCTAssertTrue(result.isAlive)
        XCTAssertEqual(result.causeOfDeath, SnakeCauseOfDeath.other)
        XCTAssertEqual(result.uuid, SnakeBot_MoveForward.info.id)
        XCTAssertEqual(result.snakeBody, originalPlayer.snakeBody)
    }

    // MARK: -

    func test200_serializationRoundtrip_level() throws {
        let uuid = UUID(uuidString: "cdeeadf2-31c9-48f4-852f-778b58086dd0")!
        guard let originalLevel: SnakeLevel = SnakeLevelManager.shared.level(id: uuid) else {
            XCTFail("Unable to locate level with uuid: '\(uuid)'")
            return
        }

        let protobufRepresentation: SnakeDatasetLevel = originalLevel.toSnakeDatasetLevel()
        let builder: SnakeLevelBuilder = try DatasetLoader.snakeLevelBuilder(levelModel: protobufRepresentation)
        let level: SnakeLevel = builder.level()

        // Things that are preserved from the original level
        XCTAssertEqual(level.id, originalLevel.id)
        XCTAssertEqual(level.size, originalLevel.size)
        XCTAssertEqual(level.emptyPositionSet, originalLevel.emptyPositionSet)

        // Things that are not preserved.
        // These properties are not needed, in order to replay a historical game.
        // And these properties are subject to change.
        XCTAssertEqual(level.initialFoodPosition, UIntVec2.zero)
        XCTAssertTrue(level.distanceBetweenClusters.isEmpty)
        XCTAssertEqual(level.player1_body.head.position, IntVec2.zero)
        XCTAssertEqual(level.player2_body.head.position, IntVec2.zero)
    }

    // MARK: -

    func snakeDatasetResult_duel0() throws -> SnakeDatasetResult {
        let url: URL = try SnakeDatasetBundle.url(forResource: "duel0.snakeDataset")
        let data: Data = try Data(contentsOf: url)
        return try SnakeDatasetResult(serializedData: data)
    }

    func test300_loadSnakeDataset_duel() throws {
        let environment: GameEnvironmentReplay = try DatasetLoader.snakeGameEnvironmentReplay(resourceName: "duel0.snakeDataset", verbose: false)
        XCTAssertGreaterThan(environment.player1Positions.count, 10)
        XCTAssertGreaterThan(environment.player2Positions.count, 10)
        XCTAssertGreaterThan(environment.foodPositions.count, 10)

        let gameState: SnakeGameState = environment.reset()
        XCTAssertTrue(gameState.player1.isInstalled)
        XCTAssertTrue(gameState.player2.isInstalled)
    }

    func test301_loadSnakeDataset_solo() throws {
        let environment: GameEnvironmentReplay = try DatasetLoader.snakeGameEnvironmentReplay(resourceName: "solo0.snakeDataset", verbose: false)
        XCTAssertGreaterThan(environment.player1Positions.count, 10)
        XCTAssertTrue(environment.player2Positions.isEmpty)
        XCTAssertGreaterThan(environment.foodPositions.count, 10)

        let gameState: SnakeGameState = environment.reset()
        XCTAssertTrue(gameState.player1.isInstalled)
        XCTAssertFalse(gameState.player2.isInstalled)
    }

    func test302_loadSnakeDataset_datasetTimestamp() throws {
        do {
            let model: SnakeDatasetResult = try snakeDatasetResult_duel0()
            let environment: GameEnvironmentReplay = try DatasetLoader.snakeGameEnvironmentReplay(model: model, verbose: false)
            XCTAssertGreaterThan(environment.datasetTimestamp, Date.distantPast)
        }

        do {
            var model: SnakeDatasetResult = try snakeDatasetResult_duel0()
            model.clearTimestamp()
            let environment: GameEnvironmentReplay = try DatasetLoader.snakeGameEnvironmentReplay(model: model, verbose: false)
            XCTAssertEqual(environment.datasetTimestamp, Date.distantPast)
        }
    }

    func test310_loadSnakeDataset_error_noSuchFile() throws {
        do {
            _ = try DatasetLoader.snakeGameEnvironmentReplay(resourceName: "nonExistingFilename.snakeDataset", verbose: false)
            XCTFail()
        } catch SnakeDatasetBundleError.custom {
            // success
        } catch {
            XCTFail()
        }
    }

    func test310_loadSnakeDataset_error_clearLevel() throws {
        var model: SnakeDatasetResult = try snakeDatasetResult_duel0()
        model.clearLevel()
        do {
            _ = try DatasetLoader.snakeGameEnvironmentReplay(model: model, verbose: false)
            XCTFail()
        } catch DatasetLoader.DatasetLoaderError.runtimeError(let message) {
            XCTAssertTrue(message.contains("level"))
        } catch {
            XCTFail()
        }
    }

    func test311_loadSnakeDataset_error_clearFirstStep() throws {
        var model: SnakeDatasetResult = try snakeDatasetResult_duel0()
        model.clearFirstStep()
        do {
            _ = try DatasetLoader.snakeGameEnvironmentReplay(model: model, verbose: false)
            XCTFail()
        } catch DatasetLoader.DatasetLoaderError.runtimeError(let message) {
            XCTAssertTrue(message.contains("firstStep"))
        } catch {
            XCTFail()
        }
    }

    func test312_loadSnakeDataset_error_clearLastStep() throws {
        var model: SnakeDatasetResult = try snakeDatasetResult_duel0()
        model.clearLastStep()
        do {
            _ = try DatasetLoader.snakeGameEnvironmentReplay(model: model, verbose: false)
            XCTFail()
        } catch DatasetLoader.DatasetLoaderError.runtimeError(let message) {
            XCTAssertTrue(message.contains("lastStep"))
        } catch {
            XCTFail()
        }
    }

    func test313_loadSnakeDataset_error_clearFoodPositions() throws {
        var model: SnakeDatasetResult = try snakeDatasetResult_duel0()
        model.foodPositions = []
        do {
            _ = try DatasetLoader.snakeGameEnvironmentReplay(model: model, verbose: false)
            XCTFail()
        } catch DatasetLoader.DatasetLoaderError.runtimeError(let message) {
            XCTAssertTrue(message.contains("food"))
        } catch {
            XCTFail()
        }
    }
}
