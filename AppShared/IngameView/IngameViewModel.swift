// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import Combine
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct ReplaySnapshot {
    let rawData: Data
    let ingameViewModel: IngameViewModel
}

public class IngameViewModel: ObservableObject {
    public let jumpToLevelSelector = PassthroughSubject<Void, Never>()
    @Published var level: SnakeLevel = SnakeLevel.empty()
    @Published var foodPosition: IntVec2? = nil
    @Published var player1Summary = "Player 1 (green)\nAlive\nLength 29"
    @Published var player2Summary = "Player 2 (blue)\nDead by collision with wall\nLength 14"
    @Published var player1Score: String = "987"
    @Published var player2Score: String = "987"
    @Published var showPauseButton: Bool = true
    @Published var levelSelector_humanVsBot = true
    @Published var player1SnakeBody: SnakeBody = SnakeBody.empty()
    @Published var player2SnakeBody: SnakeBody = SnakeBody.empty()
    @Published var player1IsInstalled: Bool = true
    @Published var player2IsInstalled: Bool = true
    @Published var player1IsAlive: Bool = true
    @Published var player2IsAlive: Bool = true
    @Published var player1PlannedPath: [IntVec2] = []
    @Published var player2PlannedPath: [IntVec2] = []
    @Published var gestureIndicatorPosition: IntVec2 = IntVec2.zero
    var replaySnapshot: ReplaySnapshot?

    private var pendingMovement_player1: SnakeBodyMovement = .dontMove
    private var pendingMovement_player2: SnakeBodyMovement = .dontMove

    private let settingStepMode: SettingStepMode
    private var isStepRepeatingForever: Bool = false

    private let gameEnvironment: GameEnvironment
    private var _gameState: SnakeGameState

    private var gameState: SnakeGameState {
        get {
            return _gameState
        }
        set {
            didUpdateGameState(oldGameState: _gameState, newGameState: newValue)
            _gameState = newValue
            syncGameState(_gameState)
        }
    }

    func didUpdateGameState(oldGameState: SnakeGameState, newGameState: SnakeGameState) {

        if oldGameState.foodPosition != newGameState.foodPosition {
            SoundItem.snake_eats.play()
        }

        let human1Alive: Bool = newGameState.player1.isInstalledAndAliveAndHuman
        let human2Alive: Bool = newGameState.player2.isInstalledAndAliveAndHuman
        if human1Alive || human2Alive {
            SoundItem.snake_step.play()
        }

        let player1Dies: Bool = oldGameState.player1.isInstalledAndAlive && newGameState.player1.isInstalledAndDead
        let player2Dies: Bool = oldGameState.player2.isInstalledAndAlive && newGameState.player2.isInstalledAndDead
        if player1Dies || player2Dies {
            SoundItem.snake_dies.play()
        }
    }

    func syncGameState(_ gameState: SnakeGameState) {
        let player1: SnakePlayer = gameState.player1
        let player2: SnakePlayer = gameState.player2

        self.level = gameState.level
        self.foodPosition = gameState.foodPosition
        self.player1SnakeBody = player1.snakeBody
        self.player2SnakeBody = player2.snakeBody
        self.player1IsInstalled = player1.isInstalled
        self.player2IsInstalled = player2.isInstalled
        self.player1IsAlive = player1.isInstalledAndAlive
        self.player2IsAlive = player2.isInstalledAndAlive

        if player1.isInstalledAndAlive {
            self.player1PlannedPath = player1.bot.plannedPath
        } else {
            self.player1PlannedPath = []
        }
        if player2.isInstalledAndAlive {
            self.player2PlannedPath = player2.bot.plannedPath
        } else {
            self.player2PlannedPath = []
        }

        func createSummaryFor(player: SnakePlayer) -> String {
            guard player.isInstalled else {
                return "\(player.id): Not installed"
            }
            var rows = [String]()
            #if os(macOS)
            rows.append("\(player.id): \(player.humanReadableRole)")
            #else
            rows.append(player.briefDescription)
            #endif
            rows.append("Length: \(player.lengthOfInstalledSnake())")
            if player.isInstalledAndDead {
                let deathExplanations: [String] = player.causesOfDeath.map { $0.humanReadableDeathExplanation }
                rows.append("Cause of death:")
                rows += deathExplanations
            }
            return rows.joined(separator: "\n")
        }
        self.player1Summary = createSummaryFor(player: player1)
        self.player2Summary = createSummaryFor(player: player2)

        self.player1Score = player1.lengthOfInstalledSnake().description
        self.player2Score = player2.lengthOfInstalledSnake().description

        if player1.isInstalledAndAlive {
            self.gestureIndicatorPosition = player1.snakeBody.head.position
        } else {
            self.gestureIndicatorPosition = IntVec2.zero
        }
    }

    init(snakeGameEnvironment: GameEnvironment) {
        self.settingStepMode = SettingStepMode(defaults: UserDefaults.standard)
        self.gameEnvironment = snakeGameEnvironment
        self._gameState = snakeGameEnvironment.reset()
        syncGameState(_gameState)
    }

    static func create() -> IngameViewModel {
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .none,
            levelName: "Level 0.csv"
        )
        let snakeGameEnvironment: GameEnvironment = GameEnvironmentInteractive(
            initialGameState: gameState
        )
        return IngameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    static func createPreview() -> IngameViewModel {
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .none,
            levelName: "Level 0.csv"
        )
        let snakeGameEnvironment: GameEnvironment = GameEnvironmentPreview(
            initialGameState: gameState
        )
        return IngameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    static func createHumanVsHuman() -> IngameViewModel {
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .human,
            levelName: "Level 6.csv"
        )
        let snakeGameEnvironment: GameEnvironment = GameEnvironmentInteractive(
            initialGameState: gameState
        )
        return IngameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createHumanVsBot() -> IngameViewModel {
        let snakeBotType: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .bot(snakeBotType: snakeBotType),
            levelName: "Level 6.csv"
        )
        let snakeGameEnvironment: GameEnvironment = GameEnvironmentInteractive(
            initialGameState: gameState
        )
        return IngameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createBotVsNone() -> IngameViewModel {
        let snakeBotType: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let gameState = SnakeGameState.create(
            player1: .bot(snakeBotType: snakeBotType),
            player2: .none,
            levelName: "Level 0.csv"
        )
        let snakeGameEnvironment: GameEnvironment = GameEnvironmentInteractive(
            initialGameState: gameState
        )
        return IngameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createBotVsBot() -> IngameViewModel {
        let snakeBotType1: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let snakeBotType2: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let gameState = SnakeGameState.create(
            player1: .bot(snakeBotType: snakeBotType1),
            player2: .bot(snakeBotType: snakeBotType2),
            levelName: "Level 6.csv"
        )
        let snakeGameEnvironment: GameEnvironment = GameEnvironmentInteractive(
            initialGameState: gameState
        )
        return IngameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createReplay(resourceName: String) -> IngameViewModel {
        let environment: GameEnvironmentReplay
        do {
            let url: URL = try SnakeDatasetBundle.url(forResource: resourceName)
            environment = try GameEnvironmentReplay.create(url: url)
        } catch {
            log.error("Unable to create replay for resource: \(resourceName). error: \(error)")
            fatalError()
        }
        return IngameViewModel(snakeGameEnvironment: environment)
    }

    static var createReplayCounter: UInt = 0

    func createReplay() -> ReplaySnapshot? {
        let counter: UInt = Self.createReplayCounter
        Self.createReplayCounter = counter + 1

        log.debug("#\(counter) Export to data")
        guard let data: Data = self.exportToData() else {
            log.error("Unable to serialize the current model")
            return nil
        }
        log.debug("#\(counter) Create replay environment")
        let environment: GameEnvironmentReplay
        do {
            environment = try DatasetLoader.snakeGameEnvironmentReplay(data: data, verbose: true)
        } catch {
            log.error("Unable to create environment with data. \(error)")
            return nil
        }
        let newModel = IngameViewModel(snakeGameEnvironment: environment)
        log.debug("#\(counter) Create replay gameviewmodel")

        return ReplaySnapshot(rawData: data, ingameViewModel: newModel)
    }

    func toInteractiveModel() -> IngameViewModel {
        let sge0 = GameEnvironmentInteractive(initialGameState: self.gameState)
        let sge1 = GameEnvironmentSaveDataset(wrapped: sge0)
        return IngameViewModel(snakeGameEnvironment: sge1)
    }

    func exportToData() -> Data? {
        guard let saveDataset = self.gameEnvironment as? GameEnvironmentSaveDataset else {
            log.error("Unable to typecast GameEnvironment to GameEnvironmentSaveDataset. \(type(of: self.gameEnvironment))")
            return nil
        }
        do {
            log.debug("will export")
            let data: Data = try saveDataset.exportResultToData()
            log.debug("did export. bytes: \(data.count)")
            return data
        } catch {
            log.error("Unable to export the result to a Data instance. \(error)")
            return nil
        }
    }

    func restartGame() {
        gameState = gameEnvironment.reset()
        resumeSteppingIfPreferred()
    }

    func userInputForPlayer1_moveForward() {
        guard gameState.player1.isInstalledAndAliveAndHuman else {
            return
        }
        pendingMovement_player1 = .moveForward
        step_humanVsAny()
    }

    func userInputForPlayer1(_ desiredHeadDirection: SnakeHeadDirection) {
        userInputForPlayer(player: gameState.player1, desiredHeadDirection: desiredHeadDirection)
    }

    func userInputForPlayer2(_ desiredHeadDirection: SnakeHeadDirection) {
        userInputForPlayer(player: gameState.player2, desiredHeadDirection: desiredHeadDirection)
    }

    private func userInputForPlayer(player: SnakePlayer, desiredHeadDirection: SnakeHeadDirection) {
        guard player.isInstalledAndAliveAndHuman else {
            return
        }
        let head: SnakeHead = player.snakeBody.head
        let movement: SnakeBodyMovement = head.moveToward(direction: desiredHeadDirection)
        guard movement != SnakeBodyMovement.dontMove else {
            userInput_stepBackwardOnce_ifSingleHuman()
            return
        }
        switch player.id {
        case .player1:
            pendingMovement_player1 = movement
        case .player2:
            pendingMovement_player2 = movement
        }
        step_humanVsAny()
    }

    private func userInput_stepBackwardOnce_ifSingleHuman() {
        var numberOfHumans: UInt = 0
        if gameState.player1.isInstalled && gameState.player1.role == .human {
            numberOfHumans += 1
        }
        if gameState.player2.isInstalled && gameState.player2.role == .human {
            numberOfHumans += 1
        }
        guard numberOfHumans > 0 else {
            log.debug("In a game without human players, it makes no sense to perform undo")
            return
        }
        guard numberOfHumans < 2 else {
            log.debug("In a game with multiple human players. Then both players have to agree when to undo, and use the undo key for it.")
            return
        }
        undo()
    }

    private func stepAutonomousIfPossible() {
        switch gameEnvironment.stepControlMode {
        case .stepRequiresHumanInput:
            // Step is not possible in a game where there are one or more humans that are alive,
            // here you have to wait for input from the humans, before the step can be executed.
            log.error("Step requires human input. Cannot execute step!")
            return
        case .reachedTheEnd:
            log.debug("Step have reached the end of the game.")
            return
        case .stepAutonomous:
            // Step can be done when there are only bots alive.
            // Step can be done when it's a replay of a historical game.
            ()
        }

        // No human input
        let action = GameEnvironment_StepAction(
            player1: .dontMove,
            player2: .dontMove
        )
        // IDEA: perform in a separate thread
        gameState = gameEnvironment.step(action: action)
    }

    private func repeatForever_stepAutonomousIfPossible() {
        guard isStepRepeatingForever else {
            log.debug("Stop repeatForever, since it has been paused.")
            return
        }
        guard gameEnvironment.stepControlMode == .stepAutonomous else {
            log.debug("Stop repeatForever, since there is nothing meaningful to be repeated.")
            isStepRepeatingForever = false
            return
        }
        log.debug("repeatForever")

        stepAutonomousIfPossible()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { [weak self] in
            self?.repeatForever_stepAutonomousIfPossible()
        }
    }

    func ingameView_playableMode_onAppear() {
        log.debug("onAppear")
        resumeSteppingIfPreferred()
    }

    func ingameView_playableMode_onDisappear() {
        log.debug("onDisappear")
        stopStepping()
    }

    func ingameView_replayMode_onAppear() {
        log.debug("onAppear")
        startStepping()
    }

    func ingameView_replayMode_onDisappear() {
        log.debug("onDisappear")
        stopStepping()
    }

    func ingameView_willPresentPauseSheet() {
        log.debug("don't do any stepping while the pause sheet is shown")
        stopStepping()
        captureReplaySnapshot()
    }

    func captureReplaySnapshot() {
        guard let replaySnapshot: ReplaySnapshot = self.createReplay() else {
            log.error("Unable to create replay data of the current model")
            self.replaySnapshot = nil
            return
        }
        log.debug("successfully created replay gameviewmodel")
        self.replaySnapshot = replaySnapshot
    }

    func pauseSheet_dismissSheetAndContinueGame() {
        log.debug("continue game")
        resumeSteppingIfPreferred()
    }

    func pauseSheet_dismissSheetAndExitGame() {
        log.debug("exit game")
        self.jumpToLevelSelector.send()
    }

    func pauseSheet_stopReplay() {
        stopStepping()
    }

    private func resumeSteppingIfPreferred() {
        switch settingStepMode.value {
        case .stepAuto:
            // The user prefer's stepping starts automatically
            startStepping()
        case .stepManual:
            // The user prefer's single stepping
            ()
        }
    }

    private func startStepping() {
        guard !isStepRepeatingForever else {
            log.debug("already busy playing.")
            return
        }
        isStepRepeatingForever = true
        repeatForever_stepAutonomousIfPossible()
    }

    private func stopStepping() {
        isStepRepeatingForever = false
    }

    func toggleStepMode() {
        if isStepRepeatingForever {
            // Pause
            settingStepMode.set(SettingStepModeValue.stepManual)
            stopStepping()
            return
        }

        // Repeated stepping is only possible in games where there are only bots.
        // If there are human players alive, then it's not possible to do stepping,
        // since that would require near instant input from the human.
        guard gameEnvironment.stepControlMode == .stepAutonomous else {
            log.debug("Start stepping ignored, since this is not a bots-only game")
            return
        }

        // Resume stepping
        settingStepMode.set(SettingStepModeValue.stepAuto)
        startStepping()
    }

    func singleStep_botsOnly() {
        settingStepMode.set(SettingStepModeValue.stepManual)
        isStepRepeatingForever = false
        stepAutonomousIfPossible()
    }

    private func step_humanVsAny() {
        var possibleGameState: SnakeGameState = self.gameState
        if self.pendingMovement_player1 != .dontMove {
            let movement: SnakeBodyMovement = self.pendingMovement_player1
            possibleGameState = possibleGameState.updatePendingMovementForPlayer1(movement)
        }
        if self.pendingMovement_player2 != .dontMove {
            let movement: SnakeBodyMovement = self.pendingMovement_player2
            possibleGameState = possibleGameState.updatePendingMovementForPlayer2(movement)
        }
        possibleGameState = possibleGameState.preventHumanCollisions()

        let isWaiting = possibleGameState.isWaitingForHumanInput()
        if isWaiting {
            //log.debug("waiting for human input")
            return
        }

        self.pendingMovement_player1 = .dontMove
        self.pendingMovement_player2 = .dontMove

        let action = GameEnvironment_StepAction(
            player1: possibleGameState.player1.pendingMovement,
            player2: possibleGameState.player2.pendingMovement
        )
        // IDEA: perform in a separate thread
        let newGameState = gameEnvironment.step(action: action)
        gameState = newGameState
    }

    func undo() {
        stopStepping()
        guard let newGameState = gameEnvironment.undo() else {
            log.debug("Reached the beginning of the history. There is nothing that can be undone.")
            return
        }
        gameState = newGameState
    }
}

extension Array where Element == SnakeGameState {
    func toPreviewGameViewModels() -> [IngameViewModel] {
        self.map {
            let sge = GameEnvironmentPreview(initialGameState: $0)
            return IngameViewModel(snakeGameEnvironment: sge)
        }
    }
}

extension SnakePlayer {
    public var briefDescription: String {
        switch self.role {
        case .none:
            return "Disabled"
        case .human:
            return "HUMAN"
        case .bot:
            return "BOT"
        }
    }
}
