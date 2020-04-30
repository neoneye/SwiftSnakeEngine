// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public struct SnakeBodyAdvancedCreate {
    private init() {}
    
    public enum CreateError: Error {
        case tooFewPositions
        case distanceOfOne
        case eatingItself
    }

    /// Advanced creation of a `SnakeBody`.
    ///
    /// For simpler and more robust function use `create(position:headDirection:length:)`.
    ///
    /// This function is more advanced, and also more fragile and may throw in lots of cases.
    ///
    /// - parameter positions: At least 2 positions must be provided. All positions must be neighbours. The positions must not overlap.
    /// - returns: `SnakeBody` instance.
    /// - throws: `CreateError` when parsing `positions` fails.
    public static func create(positions: [IntVec2]) throws -> SnakeBody {
        guard positions.count >= 2 else {
            // Expected the snake to be 2 units or longer, but it's shorter.
            throw CreateError.tooFewPositions
        }

        guard ValidateDistance.manhattanDistanceIsOne(positions) else {
            // Expected all positions to have a distance of 1 unit, but one or more doesn't satisfy this.
            throw CreateError.distanceOfOne
        }

        let positionSet = Set<IntVec2>(positions)
        guard positionSet.count == positions.count else {
            // If there are overlapping positions, then the Set will have fewer entries than the array.
            // This means that the snake is eating itself.
            throw CreateError.eatingItself
        }

        let position0: IntVec2 = positions[0]
        let position1: IntVec2 = positions[1]
        guard let initialHead = SnakeHead.create(headPosition: position0, directionPosition: position1) else {
            // Unable to create SnakeHead from the two first positions
            throw CreateError.distanceOfOne
        }

        var initialFifo = SnakeFifo<SnakeBodyPart>()
        let snakeBodyPart = SnakeBodyPart(position: position0, content: .empty)
        initialFifo.appendAndGrow(snakeBodyPart)
        var state = SnakeBody(
            fifo: initialFifo,
            head: initialHead
        )
        for (index, position) in positions.enumerated() {
            if index == 0 {
                continue
            }
            guard let movement: SnakeBodyMovement = state.head.moveToward(position) else {
                // The snake is moving backwards, and eating itself.
                throw CreateError.eatingItself
            }
            guard movement != .dontMove else {
                // The snake is not moving. Violates that all the positions are supposed to be adjacent each other.
                throw CreateError.distanceOfOne
            }
            state = state.stateForTick(movement: movement, act: .eat)
        }

        // At this point the snake has a lot of food items inside its stomach, so we have to clear the stomach.
        return state.clearedContentOfStomach()
    }

}

extension SnakeBodyAdvancedCreate.CreateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tooFewPositions:
            return "Expecting the snake to be 2 units or longer, but it's shorter."
        case .distanceOfOne:
            return "Expecting all positions to have a distance of 1 unit, but one or more positions doesn't satisfy this."
        case .eatingItself:
            return "Expecting the snake not to be eating itself."
        }
    }
}
