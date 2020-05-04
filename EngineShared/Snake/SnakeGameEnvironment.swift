// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public protocol SnakeGameEnvironment: class {
    func reset() -> SnakeGameState
    func undo()
    func step(_ gameState: SnakeGameState) -> SnakeGameState

    /// Decide about optimal path to get to the food.
    func computeNextBotMovement(_ gameState: SnakeGameState) -> SnakeGameState

    func placeNewFood(_ gameState: SnakeGameState) -> SnakeGameState

    func endOfStep(_ gameState: SnakeGameState) -> SnakeGameState
}
