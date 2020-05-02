// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

/// These tests verifies that a full serialization/deserialization roundtrip works.
/// 1st step: convert from a model representation to a protobuf representation.
/// 2nd step: convert back to a model representation.
/// 3rd step: verify that the desired model data has been preserved.
class T4000_Dataset: XCTestCase {

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
        let protobufRepresentation: SnakeGameStateModelPlayer = originalPlayer.toSnakeGameStateModelPlayer()

        let result: DatasetLoader.SnakePlayerResult = try DatasetLoader.snakePlayerResult(playerModel: protobufRepresentation)

        // Things that are preserved from the original player
        XCTAssertTrue(result.isAlive)
        XCTAssertEqual(result.snakeBody, originalPlayer.snakeBody)
        XCTAssertEqual(result.uuid, SnakePlayerRole.human.id)
    }

    func test101_serializationRoundtrip_player_human_dead() throws {
        let originalPlayer: SnakePlayer = createSnakePlayer_human().kill(.collisionWithWall)

        let protobufRepresentation: SnakeGameStateModelPlayer = originalPlayer.toSnakeGameStateModelPlayer()

        let result: DatasetLoader.SnakePlayerResult = try DatasetLoader.snakePlayerResult(playerModel: protobufRepresentation)

        // Things that are preserved from the original player
        XCTAssertFalse(result.isAlive)
        XCTAssertEqual(result.snakeBody, originalPlayer.snakeBody)
        XCTAssertEqual(result.uuid, SnakePlayerRole.human.id)
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
        let protobufRepresentation: SnakeGameStateModelPlayer = originalPlayer.toSnakeGameStateModelPlayer()

        let result: DatasetLoader.SnakePlayerResult = try DatasetLoader.snakePlayerResult(playerModel: protobufRepresentation)

        // Things that are preserved from the original player
        XCTAssertTrue(result.isAlive)
        XCTAssertEqual(result.snakeBody, originalPlayer.snakeBody)
        XCTAssertEqual(result.uuid, SnakeBot_MoveForward.info.id)
    }

    func test200_serializationRoundtrip_level() throws {
        let uuid = UUID(uuidString: "cdeeadf2-31c9-48f4-852f-778b58086dd0")!
        guard let originalLevel: SnakeLevel = SnakeLevelManager.shared.level(id: uuid) else {
            XCTFail("Unable to locate level with uuid: '\(uuid)'")
            return
        }

        let protobufRepresentation: SnakeGameStateModelLevel = originalLevel.toSnakeGameStateModelLevel()
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

}
