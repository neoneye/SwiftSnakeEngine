// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

extension SnakeGameState {
    public func isWaitingForHumanInput() -> Bool {
        if self.player1.isInstalledAndAliveAndHuman && self.player1.pendingMovement == .dontMove {
            return true
        }
        if self.player2.isInstalledAndAliveAndHuman && self.player2.pendingMovement == .dontMove {
            return true
        }
        return false
    }
}
