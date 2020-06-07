// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Detect if a player has gotten stuck and is doing the same things over and over.
///
/// Undo is possible in the UI. This makes debugging easiser, but it also complicates the data model.
/// The user can step back/forward in time and inspect what is going on.
///
/// The `StuckSnakeDetectorForwardHistory` in itself does not support undo.
///
/// The `StuckSnakeDetector` makes undo possible.
public class StuckSnakeDetector {
    private let humanReadableName: String
    private var historical_snakeBodies: [SnakeBody] = []
    private var detector: StuckSnakeDetectorForwardHistory

    public init(humanReadableName: String) {
        self.humanReadableName = humanReadableName
        self.detector = StuckSnakeDetectorForwardHistory(humanReadableName: humanReadableName)
    }

    public func reset() {
        self.historical_snakeBodies.removeAll()
        self.detector = StuckSnakeDetectorForwardHistory(humanReadableName: humanReadableName)
    }

    public func append(_ body: SnakeBody) {
        self.detector.append(body)
        self.historical_snakeBodies.append(body)
    }

    /// Undo, by removing the last event and replay all the historical events.
    public func undo() {
        guard !self.historical_snakeBodies.isEmpty else {
            // When there is nothing to undo, then do nothing.
            return
        }
        self.historical_snakeBodies.removeLast()
        self.detector = StuckSnakeDetectorForwardHistory(humanReadableName: humanReadableName)
        for body in self.historical_snakeBodies {
            self.detector.append(body)
        }
    }

    public var isStuck: Bool {
        return self.detector.isStuck
    }
}


/// Detect if a player has gotten stuck and is doing the same things over and over.
///
/// It's only possible to append items to this class.
///
/// There is no way to undo. Instead use the `StuckSnakeDetector` class.
public class StuckSnakeDetectorForwardHistory {
    private let humanReadableName: String
    private var historical_snakeBodies = Set<SnakeBody>()
    private var score: UInt = 0
    public private (set) var isStuck = false

    public init(humanReadableName: String) {
        self.humanReadableName = humanReadableName
    }

    public func reset() {
        historical_snakeBodies.removeAll()
        score = 0
        isStuck = false
    }

    public func append(_ body: SnakeBody) {
        guard historical_snakeBodies.contains(body) else {
            historical_snakeBodies.insert(body)
            if score > 1 {
                score -= 1
            } else {
                score = 0
            }
            return
        }
        log.debug("\(humanReadableName) has possible become stuck!")
        score += 2
        if score >= 5 {
            log.debug("\(humanReadableName) has almost certainly become stuck!")
            isStuck = true
        }
    }
}

extension StuckSnakeDetector {
    /// While playing as a human, I find it annoying to get killed because
    /// I'm doing the same patterns over and over.
    /// So this "stuck in loop" detection only applies to bots.
    internal func killBotIfStuckInLoop(_ player: SnakePlayer) -> SnakePlayer {
        guard player.isInstalledAndAlive && player.isBot else {
            return player
        }
        self.append(player.snakeBody)
        if self.isStuck {
            return player.kill(.stuckInALoop)
        } else {
            return player
        }
    }
}
