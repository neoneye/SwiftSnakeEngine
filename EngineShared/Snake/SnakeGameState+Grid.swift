// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum GridCell {
    case empty
    case food
    case wall
    case player1
    case player2
}

extension SnakeGameState {
    // Create a NxN grid with obstacles surrounding the center of attention, typically the snake head.
    public func grid(radius: UInt32, center: IntVec2) -> Array2<GridCell> {
        let size: UInt32 = radius * 2 + 1
        let offset: Int32 = Int32(radius)
        let grid = Array2<GridCell>(size: UIntVec2(x: size, y: size), defaultValue: GridCell.empty)

        // Draw the level walls as obstacles
        for y: Int32 in 0..<Int32(size) {
            for x: Int32 in 0..<Int32(size) {
                let position: IntVec2 = center.offsetBy(dx: x-offset, dy: y-offset)
                guard let cell: SnakeLevelCell = level.getValue(position) else {
                    // Treat positions outside the level as obstacles.
                    grid[x, y] = .wall
                    continue
                }
                if cell == .wall {
                    grid[x, y] = .wall
                }

                if position == self.foodPosition {
                    grid[x, y] = .food
                }
            }
        }

        // Draw players
        let player1PositionSet: Set<IntVec2>
        if player1.isInstalled {
            player1PositionSet = player1.snakeBody.positionSet()
        } else {
            player1PositionSet = []
        }
        let player2PositionSet: Set<IntVec2>
        if player2.isInstalled {
            player2PositionSet = player2.snakeBody.positionSet()
        } else {
            player2PositionSet = []
        }
        for y: Int32 in 0..<Int32(size) {
            for x: Int32 in 0..<Int32(size) {
                let position: IntVec2 = center.offsetBy(dx: x-offset, dy: y-offset)
                if player1PositionSet.contains(position) {
                    grid[x, y] = .player1
                }
                if player2PositionSet.contains(position) {
                    grid[x, y] = .player2
                }
            }
        }

        return grid
    }

}
