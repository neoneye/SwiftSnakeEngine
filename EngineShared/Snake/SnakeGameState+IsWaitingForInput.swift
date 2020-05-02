// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

extension SnakeGameState {
    public func isWaitingForInput() -> Bool {
        if self.player1.isInstalled && self.player1.isAlive && self.player1.pendingMovement == .dontMove {
            return true
        }
        if self.player2.isInstalled && self.player2.isAlive && self.player2.pendingMovement == .dontMove {
            return true
        }
        return false
    }
}
