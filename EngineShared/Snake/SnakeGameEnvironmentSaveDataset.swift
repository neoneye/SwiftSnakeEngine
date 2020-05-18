// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeGameEnvironmentSaveDataset: SnakeGameEnvironment {
    private let wrapped: SnakeGameEnvironment
    private var trainingSessionUUID: UUID
    private var trainingSessionURLs: [URL]

    public init(wrapped: SnakeGameEnvironment) {
        self.trainingSessionUUID = UUID()
        self.trainingSessionURLs = []
        self.wrapped = wrapped
    }

    public func reset() -> SnakeGameState {
        trainingSessionUUID = UUID()
        trainingSessionURLs = []
        return wrapped.reset()
    }

    public func undo() -> SnakeGameState? {
        // IDEA: deal with undo and discard mis-steps.
        //
        // In a game with human players, the 'undo' function is often used.
        // Ideally the dataset file should contain all the data. Both steps and mis-steps.
        // For now I want to eliminate all the mis-steps. It will appear as if the human
        // did do a much better game without any mis-steps at all.
        // In the future I may choose to include all mis-steps in the result file.
        return wrapped.undo()
    }

    public func step(action: SnakeGameAction) -> SnakeGameState {
        let gameState: SnakeGameState = wrapped.step(action: action)
        let url: URL = gameState.saveTrainingData(trainingSessionUUID: self.trainingSessionUUID)
        trainingSessionURLs.append(url)

        // The game is over when both players are dead
        let player1Alive: Bool = gameState.player1.isInstalledAndAlive
        let player2Alive: Bool = gameState.player2.isInstalledAndAlive
        let oneOrMorePlayersAreAlive: Bool = player1Alive || player2Alive
        if !oneOrMorePlayersAreAlive {
            postProcess()
        }

        return gameState
    }

    public func postProcess() {
        // IDEA: Determine the winner: the longest snake, or the longest lived snake, or a combo?
        // IDEA: pass on which player won/loose.
        PostProcessTrainingData.process(
            trainingSessionUUID: self.trainingSessionUUID,
            urls: self.trainingSessionURLs
        )
    }
}
