// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public struct SnakeGameAction {
    public let player1: SnakeBodyMovement
    public let player2: SnakeBodyMovement

    public init(player1: SnakeBodyMovement, player2: SnakeBodyMovement) {
        self.player1 = player1
        self.player2 = player2
    }
}

public protocol SnakeGameEnvironment: class {
    /// Rewind the game to the initial state.
    func reset() -> SnakeGameState

    /// Undo to the previous step.
    ///
    /// - returns: The new state of world. And `nil` when there is no previous step that can be rolled back to.
    func undo() -> SnakeGameState?

    func step(action: SnakeGameAction) -> SnakeGameState
}
