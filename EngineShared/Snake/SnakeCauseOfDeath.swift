// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakeCauseOfDeath {
    /// Used when loading a `.snakeDataset` file, and the player have died from one or more reasons,
    /// that are not included in the `SnakeDataset.proto` file.
    ///
    /// There can only be 1 causeOfDeath stored in the `.snakeDataset` file,
    /// so `.other` is used whenever there are 2 or more causes of death.
    case other

    /// The player attempted to move into a wall, which is deadly.
    case collisionWithWall

    /// The player attempted to move into itself. Eating snake is deadly.
    case collisionWithItself

    /// The player attempted to move into the opponent player. Eating another snake is also deadly.
    case collisionWithOpponent

    /// The AI continued doing the same moves over and over, which is deadly.
    case stuckInALoop

    /// The player have died from starvation.
    case noMoreFood

    /// Used during development, to run a few iterations of a game, and then automatically terminate the game.
    case killAfterAFewTimeSteps
}

extension SnakeCauseOfDeath {
    public var humanReadableDeathExplanation: String {
        let s0 = self.deathExplanation_title
        let s1 = self.deathExplanation_subtitle
        return s0 + "\n" + s1
    }

    public var deathExplanation_title: String {
        switch self {
        case .other:
            return "Unspecified type of death"
        case .collisionWithWall:
            return "Death by wall!"
        case .collisionWithItself:
            return "Self-cannibalism!"
        case .collisionWithOpponent:
            return "Eating opponent!"
        case .stuckInALoop:
            return "Stuck in a loop!"
        case .noMoreFood:
            return "Starvation!"
        case .killAfterAFewTimeSteps:
            return "Autokill!"
        }
    }

    public var deathExplanation_subtitle: String {
        switch self {
        case .other:
            return "Dead by one or more unspecified causes!"
        case .collisionWithWall:
            return "Cannot go through walls."
        case .collisionWithItself:
            return "Eating oneself is deadly."
        case .collisionWithOpponent:
            return "The snakes cannot eat each other, since it's deadly."
        case .stuckInALoop:
            return "Expected the snake to make progress growing, but the snake continues doing the same moves over and over."
        case .noMoreFood:
            return "There is no more food."
        case .killAfterAFewTimeSteps:
            return "Killed automatically after a few steps.\nThis is useful during development."
        }
    }
}
