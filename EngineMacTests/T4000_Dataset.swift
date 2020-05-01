// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T4000_Dataset: XCTestCase {

    func test100_level() throws {
        // This test verifies that a full serialization/deserialization roundtrip works.
        // 1st step: convert from a model representation to a protobuf representation.
        // 2nd step: convert back to a model representation.
        // 3rd step: verify that the desired model data has been preserved.

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
