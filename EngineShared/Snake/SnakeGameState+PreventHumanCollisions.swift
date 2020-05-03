// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

extension SnakeGameState {

    /// Checks the human inputs and prevent humans from colliding with walls/snakes
    public func preventHumanCollisions() -> SnakeGameState {
        var gameState: SnakeGameState = self
        gameState = gameState.preventHumanCollisions_player1()
        gameState = gameState.preventHumanCollisions_player2()
        return gameState
    }

    private func preventHumanCollisions_player1() -> SnakeGameState {
        guard self.player1.isHumanWithPendingMovement else {
            return self
        }
        let detector = SnakeCollisionDetector.create(
            level: self.level,
            foodPosition: self.foodPosition,
            player1: self.player1,
            player2: self.player2
        )
        detector.process()
        guard !detector.player1Alive else {
            return self
        }
        log.info("player1 will collide with something. \(detector.collisionType1). Preventing this movement.")
        return self.updatePendingMovementForPlayer1(.dontMove)
    }

    private func preventHumanCollisions_player2() -> SnakeGameState {
        guard self.player2.isHumanWithPendingMovement else {
            return self
        }
        let detector = SnakeCollisionDetector.create(
            level: self.level,
            foodPosition: self.foodPosition,
            player1: self.player1,
            player2: self.player2
        )
        detector.process()
        guard !detector.player2Alive else {
            return self
        }
        log.info("player2 will collide with something. \(detector.collisionType2). Preventing this movement.")
        return self.updatePendingMovementForPlayer2(.dontMove)
    }
}

extension SnakePlayer {
    fileprivate var isHumanWithPendingMovement: Bool {
        guard isInstalledAndAlive else {
            return false
        }
        guard role == .human else {
            return false
        }
        let hasPendingMovement: Bool = self.pendingMovement != .dontMove
        return hasPendingMovement
    }
}
