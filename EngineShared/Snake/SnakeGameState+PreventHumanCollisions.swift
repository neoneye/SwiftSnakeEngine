// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

extension SnakeGameState {

    /// Checks the human inputs and prevent humans from colliding with walls/snakes
    public func preventHumanCollisions() -> SnakeGameState {
        var gameState: SnakeGameState = self

        if gameState.player1.role == .human && gameState.player1.isAlive && gameState.player1.pendingMovement != .dontMove {
            let detector = SnakeCollisionDetector.create(
                level: gameState.level,
                foodPosition: gameState.foodPosition,
                player1: gameState.player1,
                player2: gameState.player2
            )
            detector.process()
            if detector.player1Alive == false {
                log.info("player1 will collide with something. \(detector.collisionType1). Preventing this movement.")
                gameState = gameState.updatePendingMovementForPlayer1(.dontMove)
            }
        }
        if gameState.player2.role == .human && gameState.player2.isAlive && gameState.player2.pendingMovement != .dontMove {
            let detector = SnakeCollisionDetector.create(
                level: gameState.level,
                foodPosition: gameState.foodPosition,
                player1: gameState.player1,
                player2: gameState.player2
            )
            detector.process()
            if detector.player2Alive == false {
                log.info("player2 will collide with something. \(detector.collisionType2). Preventing this movement.")
                gameState = gameState.updatePendingMovementForPlayer2(.dontMove)
            }
        }
        return gameState
    }
}
