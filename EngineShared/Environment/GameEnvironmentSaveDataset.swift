// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class GameEnvironmentSaveDataset: GameEnvironment {
    private let wrapped: GameEnvironment
    private var stepArray: [SnakeDatasetStep]
    private var level: SnakeLevel?

    public init(wrapped: GameEnvironment) {
        self.wrapped = wrapped
        self.stepArray = []
        self.level = nil
    }

    public func reset() -> SnakeGameState {
        stepArray = []
        let gameState: SnakeGameState = wrapped.reset()
        stepArray.append(gameState.toSnakeDatasetStep())
        level = gameState.level
        return gameState
    }

    public func undo() -> SnakeGameState? {
        // In a game with human players, the 'undo' function is often used.
        // Ideally the dataset file should contain all the data. Both steps and mis-steps.
        // For now I'm eliminating all the mis-steps. It will appear as if the human
        // did do a much better game without any mis-steps at all.
        // In the future I may choose to include all mis-steps in the result file.
        guard let gameState: SnakeGameState = wrapped.undo() else {
            return nil
        }
        // Discard the mis-step.
        _ = stepArray.popLast()
        return gameState
    }

    public var stepControlMode: GameEnvironment_StepControlMode {
        return wrapped.stepControlMode
    }

    public func step(action: GameEnvironment_StepAction) -> SnakeGameState {
        let gameState: SnakeGameState = wrapped.step(action: action)
        stepArray.append(gameState.toSnakeDatasetStep())

        // The game is over when both players are dead
        let player1Alive: Bool = gameState.player1.isInstalledAndAlive
        let player2Alive: Bool = gameState.player2.isInstalledAndAlive
        let oneOrMorePlayersAreAlive: Bool = player1Alive || player2Alive
        if !oneOrMorePlayersAreAlive {
            postProcess()
        }

        return gameState
    }

    public enum SaveDatasetError: Error {
        case runtimeError(message: String)
    }

    public func postProcess() {
        let processor: PostProcessTrainingData
        do {
            processor = try createPostProcessor()
        } catch {
            log.error("Unable to create postprocessor. \(error)")
            return
        }
        let trainingSessionUUID = UUID()
        processor.saveToTempoaryFile(trainingSessionUUID: trainingSessionUUID)
    }

    public func exportResultToData() throws -> Data {
        let processor: PostProcessTrainingData = try createPostProcessor()
        return processor.toData()
    }

    private func createPostProcessor() throws -> PostProcessTrainingData {
        guard let level: SnakeLevel = self.level else {
            throw SaveDatasetError.runtimeError(message: "Expected level to be non-nil, but got nil. Maybe reset() was never invoked. Cannot generate a dataset file.")
        }
        let levelDataset: SnakeDatasetLevel = level.toSnakeDatasetLevel()
        let processor = PostProcessTrainingData(level: levelDataset, stepArray: stepArray)
        return processor
    }
}
