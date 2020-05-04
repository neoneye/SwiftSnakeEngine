// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

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

}

extension Array where Element == SnakeDatasetPosition {
    internal func toUIntVec2Array() -> [UIntVec2] {
        self.map { UIntVec2(x: $0.x, y: $0.y) }
    }

    internal func toIntVec2Array() -> [IntVec2] {
        self.map { IntVec2(x: Int32($0.x), y: Int32($0.y)) }
    }
}

