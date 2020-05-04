// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public protocol SnakeGameEnvironment: class {
    /// Rewind the game to the initial state.
    func reset() -> SnakeGameState

    /// Undo to the previous step.
    ///
    /// - returns: The new state of world. And `nil` when there is no previous step that can be rolled back to.
    func undo() -> SnakeGameState?

    func step(_ gameState: SnakeGameState) -> SnakeGameState

    /// Decide about optimal path to get to the food.
    func computeNextBotMovement(_ gameState: SnakeGameState) -> SnakeGameState

    func placeNewFood(_ gameState: SnakeGameState) -> SnakeGameState

    func endOfStep(_ gameState: SnakeGameState) -> SnakeGameState
}
