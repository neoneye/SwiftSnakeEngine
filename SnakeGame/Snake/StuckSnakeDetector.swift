// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Detect if a player has gotten stuck and doing the same things over and over.
public class StuckSnakeDetector {
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

    public func process(body: SnakeBody) {
        guard historical_snakeBodies.contains(body) else {
            historical_snakeBodies.insert(body)
            if score > 1 {
                score -= 1
            } else {
                score = 0
            }
            return
        }
        print("\(humanReadableName) has possible become stuck!")
        score += 2
        if score >= 5 {
            print("\(humanReadableName) has almost certainly become stuck!")
            isStuck = true
        }
    }
}
