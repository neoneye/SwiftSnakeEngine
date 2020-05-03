// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakeCauseOfDeath {
    case collisionWithWall
    case collisionWithItself
    case collisionWithOpponent
    case stuckInALoop
    case noMoreFood
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
