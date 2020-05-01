// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class DatasetLoader {
    internal static func snakeLevelBuilder(levelModel: SnakeGameStateModelLevel) -> SnakeLevelBuilder {
        let uuidString: String = levelModel.uuid
        guard let uuid: UUID = UUID(uuidString: uuidString) else {
            log.error("Expected a valid uuid, but got: '\(uuidString)'")
            fatalError()
        }
        guard levelModel.width >= 3 && levelModel.height >= 3 else {
            log.error("Expected size of level to be 3 or more, but got less. Cannot create level.")
            fatalError()
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

}
