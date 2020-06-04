// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Used by the level selector where heavy loading is to be avoided.
public class GameEnvironmentPreview: GameEnvironment {
    private let initialGameState: SnakeGameState

    public init(initialGameState: SnakeGameState) {
        self.initialGameState = initialGameState
    }

    public func reset() -> SnakeGameState {
        return initialGameState
    }

    public func undo() -> SnakeGameState? {
        return nil
    }

    public var stepControlMode: GameEnvironment_StepControlMode {
        return .reachedTheEnd
    }

    public func step(action: GameEnvironment_StepAction) -> SnakeGameState {
        return initialGameState
    }
}
