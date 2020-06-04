// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public struct GameEnvironment_StepAction {
    public let player1: SnakeBodyMovement
    public let player2: SnakeBodyMovement

    public init(player1: SnakeBodyMovement, player2: SnakeBodyMovement) {
        self.player1 = player1
        self.player2 = player2
    }
}

public enum GameEnvironment_StepControlMode {
    /// In a game where there are one or two human players, then the `step()` function can
    /// only be invoked when the human players have prepared their movements.
    /// As long as the human players are alive, this returns `stepRequiresHumanInput`.
    /// When all the players are dead then, stepping is no longer possible and `reachedTheEnd` is returned.
    case stepRequiresHumanInput

    /// In a game where it's (bots vs bots), then there are no human players to wait for,
    /// so the game can step repeatedly without any human input.
    /// As long as the players are alive, this returns `stepAutonomous`.
    /// When all the players are dead then, stepping is no longer possible and `reachedTheEnd` is returned.
    ///
    /// In a replay of a historical game (human vs human), then there is no need for human input,
    /// since the movements are historical data. This returns `stepAutonomous`.
    /// When the end of the historical data have been reached, then `reachedTheEnd` is returned.
    case stepAutonomous

    /// When all the players are dead, then `reachedTheEnd` is returned.
    /// After this point it makes no sense to do repeated stepping.
    ///
    /// In a preview of a game, then it's only the first step of the game that is being simulated,
    /// so stepping is not possible. This returns `reachedTheEnd`.
    case reachedTheEnd
}

public protocol GameEnvironment: class {
    /// Rewind the game to the initial state.
    ///
    /// - returns: The initial state of the world.
    func reset() -> SnakeGameState

    /// Undo to the previous step.
    ///
    /// - returns: The new state of the world. And `nil` when there is no previous step that can be rolled back to.
    func undo() -> SnakeGameState?

    /// Determine if it's possible to invoke `step()` without human input.
    ///
    /// No human input is needed, when:
    /// - It's a replay of a historic game.
    /// - It's a bot vs. bot game.
    /// - It's a human vs bot game, and the human have died and the bot is still alive.
    ///
    /// Human input is needed when it's an interactive game with one or two human players.
    var stepControlMode: GameEnvironment_StepControlMode { get }

    /// Execute the game mechanics for one time step.
    /// 
    /// - parameter action: Human input from keyboard or touch display for controlling the snakes.
    /// - returns: The new state of the world.
    func step(action: GameEnvironment_StepAction) -> SnakeGameState
}
