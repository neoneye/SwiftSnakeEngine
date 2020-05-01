// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class DatasetLoader {
    enum DatasetLoaderError: Error {
        case runtimeError(message: String)
    }

    internal static func snakeLevelBuilder(levelModel: SnakeGameStateModelLevel) throws -> SnakeLevelBuilder {
        let uuidString: String = levelModel.uuid
        guard let uuid: UUID = UUID(uuidString: uuidString) else {
            throw DatasetLoaderError.runtimeError(message: "Expected a valid uuid, but got: '\(uuidString)'")
        }
        guard levelModel.width >= 3 && levelModel.height >= 3 else {
            throw DatasetLoaderError.runtimeError(message: "Expected size of level to be 3 or more, but got less. Cannot create level.")
        }
        let size = UIntVec2(x: levelModel.width, y: levelModel.height)
        let emptyPositions: [UIntVec2] = levelModel.emptyPositions.map { UIntVec2(x: $0.x, y: $0.y) }
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
        let isAlive: Bool
        let snakeBody: SnakeBody
    }

    internal static func snakePlayerResult(playerModel: SnakeGameStateModelPlayer) throws -> SnakePlayerResult {
        let positions: [IntVec2] = playerModel.bodyPositions.map { IntVec2(x: Int32($0.x), y: Int32($0.y)) }
        let snakeBody: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: positions.reversed())
        return SnakePlayerResult(
            isAlive: playerModel.alive,
            snakeBody: snakeBody
        )
    }

}
