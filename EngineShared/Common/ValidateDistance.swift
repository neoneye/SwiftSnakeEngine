// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class ValidateDistance {
    private init() {}

    /// Ensure that all the positions are adjacent to each other.
    ///
    /// In a snake game, all player moves must be by a distance of 1 unit.
    ///
    /// Rule violation: The snake must never stand still, so it cannot move by 0 unit.
    ///
    /// Rule violation: The snake must not move by more than 1 unit.
    public static func manhattanDistanceIsOne(_ positions: [IntVec2]) -> Bool {
        for (index, position) in positions.enumerated() {
            if index == 0 {
                continue
            }
            let diff = position.subtract(positions[index - 1])
            let manhattanDistance = abs(diff.x) + abs(diff.y)
            guard manhattanDistance == 1 else {
                return false
            }
        }
        return true
    }
}
