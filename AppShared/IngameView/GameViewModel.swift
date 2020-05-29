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

// IDEA: rename to IngameViewModel
public class GameViewModel: ObservableObject {
    public let jumpToLevelSelector = PassthroughSubject<Void, Never>()
    @Published var level: SnakeLevel = SnakeLevel.empty()
    @Published var foodPosition: IntVec2? = nil
    @Published var player1Summary = "Player 1 (green)\nAlive\nLength 29"
    @Published var player2Summary = "Player 2 (blue)\nDead by collision with wall\nLength 14"
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

    private var pendingMovement_player1: SnakeBodyMovement = .dontMove
    private var pendingMovement_player2: SnakeBodyMovement = .dontMove

    private let settingStepMode: SettingStepMode
    private var isStepRepeatingForever: Bool = false

    private let snakeGameEnvironment: SnakeGameEnvironment
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

        if player1.isInstalledAndAlive {
            self.gestureIndicatorPosition = player1.snakeBody.head.position
        } else {
            self.gestureIndicatorPosition = IntVec2.zero
        }
    }

    init(snakeGameEnvironment: SnakeGameEnvironment) {
        self.settingStepMode = SettingStepMode(defaults: UserDefaults.standard)
        self.snakeGameEnvironment = snakeGameEnvironment
        self._gameState = snakeGameEnvironment.reset()
        syncGameState(_gameState)
    }

    static func create() -> GameViewModel {
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .none,
            levelName: "Level 0.csv"
        )
        let snakeGameEnvironment: SnakeGameEnvironment = SnakeGameEnvironmentInteractive(
            initialGameState: gameState
        )
        return GameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    static func createPreview() -> GameViewModel {
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .none,
            levelName: "Level 0.csv"
        )
        let snakeGameEnvironment: SnakeGameEnvironment = SnakeGameEnvironmentPreview(
            initialGameState: gameState
        )
        return GameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    static func createHumanVsHuman() -> GameViewModel {
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .human,
            levelName: "Level 6.csv"
        )
        let snakeGameEnvironment: SnakeGameEnvironment = SnakeGameEnvironmentInteractive(
            initialGameState: gameState
        )
        return GameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createHumanVsBot() -> GameViewModel {
        let snakeBotType: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let gameState = SnakeGameState.create(
            player1: .human,
            player2: .bot(snakeBotType: snakeBotType),
            levelName: "Level 6.csv"
        )
        let snakeGameEnvironment: SnakeGameEnvironment = SnakeGameEnvironmentInteractive(
            initialGameState: gameState
        )
        return GameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createBotVsNone() -> GameViewModel {
        let snakeBotType: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let gameState = SnakeGameState.create(
            player1: .bot(snakeBotType: snakeBotType),
            player2: .none,
            levelName: "Level 0.csv"
        )
        let snakeGameEnvironment: SnakeGameEnvironment = SnakeGameEnvironmentInteractive(
            initialGameState: gameState
        )
        return GameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createBotVsBot() -> GameViewModel {
        let snakeBotType1: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let snakeBotType2: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let gameState = SnakeGameState.create(
            player1: .bot(snakeBotType: snakeBotType1),
            player2: .bot(snakeBotType: snakeBotType2),
            levelName: "Level 6.csv"
        )
        let snakeGameEnvironment: SnakeGameEnvironment = SnakeGameEnvironmentInteractive(
            initialGameState: gameState
        )
        return GameViewModel(snakeGameEnvironment: snakeGameEnvironment)
    }

    class func createReplay() -> GameViewModel {
        let environment = SnakeGameEnvironmentReplay.create()
        return GameViewModel(snakeGameEnvironment: environment)
    }

    func createReplay() -> GameViewModel? {
        guard let data: Data = self.exportToData() else {
            log.error("Unable to serialize the current model")
            return nil
        }
        log.debug("successfully obtained a serialized version of the current model.")
        let environment: SnakeGameEnvironmentReplay = SnakeGameEnvironmentReplay.create(data: data)
        let newModel = GameViewModel(snakeGameEnvironment: environment)
        log.debug("created gameviewmodel with the replay data")
        return newModel
    }

    func toInteractiveModel() -> GameViewModel {
        let sge0 = SnakeGameEnvironmentInteractive(initialGameState: self.gameState)

        let sge1: SnakeGameEnvironment
        if AppConstant.saveTrainingData {
            sge1 = SnakeGameEnvironmentSaveDataset(wrapped: sge0)
        } else {
            sge1 = sge0
        }
        return GameViewModel(snakeGameEnvironment: sge1)
    }

    func exportToData() -> Data? {
        guard let saveDataset = self.snakeGameEnvironment as? SnakeGameEnvironmentSaveDataset else {
            log.error("Unable to typecast snakeGameEnvironment to SnakeGameEnvironmentSaveDataset. \(type(of: self.snakeGameEnvironment))")
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
        gameState = snakeGameEnvironment.reset()
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

    /// Single step forward can only be done when there are only bots.
    ///
    /// In a game where there are one or more humans that are alive,
    /// here you have to wait for input from the humans, before the step can be executed.
    /// This complicates things.
    ///
    /// For simplicity this function deals with games where there one or more bots,
    /// And there are zero humans alive.
    private var isStepPossible_botsOnly: Bool {
        var botCount: UInt = 0
        var nonBotCount: UInt = 0
        let players: [SnakePlayer] = [gameState.player1, gameState.player2]
        for player in players {
            if player.isInstalledAndAlive {
                if player.isBot {
                    botCount += 1
                } else {
                    nonBotCount += 1
                }
            }
        }
        guard nonBotCount == 0 && botCount > 0 else {
            return false
        }
        return true
    }

    private func step_botsOnly() {
        guard isStepPossible_botsOnly else {
            log.debug("Single step forward can only be done when there are only bots")
            return
        }

        // No human input
        let action = SnakeGameAction(
            player1: .dontMove,
            player2: .dontMove
        )
        // IDEA: perform in a separate thread
        gameState = snakeGameEnvironment.step(action: action)
    }

    private func repeatForever_step_botsOnly() {
        guard isStepRepeatingForever else {
            log.debug("Stop repeatForever, since it has been paused.")
            return
        }
        guard isStepPossible_botsOnly else {
            log.debug("Stop repeatForever, since there is nothing meaningful to be repeated.")
            isStepRepeatingForever = false
            return
        }
        log.debug("repeatForever")

        step_botsOnly()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { [weak self] in
            self?.repeatForever_step_botsOnly()
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
    }

    func pauseSheet_dismissSheetAndContinueGame() {
        log.debug("continueGame")
        resumeSteppingIfPreferred()
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
        repeatForever_step_botsOnly()
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
        guard isStepPossible_botsOnly else {
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
        step_botsOnly()
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

        let isWaiting = possibleGameState.isWaitingForInput()
        if isWaiting {
            //log.debug("waiting for input")
            return
        }

        self.pendingMovement_player1 = .dontMove
        self.pendingMovement_player2 = .dontMove

        let action = SnakeGameAction(
            player1: possibleGameState.player1.pendingMovement,
            player2: possibleGameState.player2.pendingMovement
        )
        // IDEA: perform in a separate thread
        let newGameState = snakeGameEnvironment.step(action: action)
        gameState = newGameState
    }

    func undo() {
        stopStepping()
        guard let newGameState = snakeGameEnvironment.undo() else {
            log.debug("Reached the beginning of the history. There is nothing that can be undone.")
            return
        }
        gameState = newGameState
    }
}

extension Array where Element == SnakeGameState {
    func toPreviewGameViewModels() -> [GameViewModel] {
        self.map {
            let sge = SnakeGameEnvironmentPreview(initialGameState: $0)
            return GameViewModel(snakeGameEnvironment: sge)
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

extension SnakePlayer {
    var isInstalledAndAliveAndHuman: Bool {
        return self.isInstalledAndAlive && self.role == .human
    }
}
