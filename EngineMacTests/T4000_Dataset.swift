// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T4000_Dataset: XCTestCase {

    func test100_level() {
        let uuid = UUID(uuidString: "cdeeadf2-31c9-48f4-852f-778b58086dd0")!
        guard let originalLevel: SnakeLevel = SnakeLevelManager.shared.level(id: uuid) else {
            XCTFail("Unable to locate level with uuid: '\(uuid)'")
            return
        }

        let model: SnakeGameStateModelLevel = originalLevel.toSnakeGameStateModelLevel()

        let builder: SnakeLevelBuilder = DatasetLoader.snakeLevelBuilder(levelModel: model)
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
    }

}
