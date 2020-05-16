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
    public let userInterfaceStyle = PassthroughSubject<Void, Never>()
    @Published var level: SnakeLevel = SnakeLevel.empty()
    @Published var foodPosition: IntVec2 = IntVec2.zero
    @Published var player1Length: UInt = 1
    @Published var player2Length: UInt = 1
    @Published var player1Info = "Player 1 (green)\nAlive\nLength 29"
    @Published var player2Info = "Player 2 (blue)\nDead by collision with wall\nLength 14"
    @Published var showPauseButton: Bool = true
    @Published var levelSelector_humanVsBot = true
    @Published var levelSelector_visible = true
    @Published var levelSelector_insetTop: CGFloat = 0
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

    var isPlaying: Bool = false

    private let snakeGameEnvironment: SnakeGameEnvironment
    private var _gameState: SnakeGameState

    private var gameState: SnakeGameState {
        get {
            return _gameState
        }
        set {
            _gameState = newValue
            syncGameState(_gameState)
        }
    }

    func syncGameState(_ gameState: SnakeGameState) {
        let player1: SnakePlayer = gameState.player1
        let player2: SnakePlayer = gameState.player2

        self.level = gameState.level
        self.foodPosition = gameState.foodPosition ?? IntVec2.zero
        self.player1SnakeBody = player1.snakeBody
        self.player2SnakeBody = player2.snakeBody
        self.player1IsInstalled = player1.isInstalled
        self.player2IsInstalled = player2.isInstalled
        self.player1IsAlive = player1.isInstalledAndAlive
        self.player2IsAlive = player2.isInstalledAndAlive
        self.player1Length = player1.lengthOfInstalledSnake()
        self.player2Length = player2.lengthOfInstalledSnake()

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

        if player1.isInstalledAndAlive {
            self.gestureIndicatorPosition = player1.snakeBody.head.position
        } else {
            self.gestureIndicatorPosition = IntVec2.zero
        }
    }

    #if os(iOS)
    @Published var iOS_soundEffectsEnabled: Bool = SoundEffectController().value {
        didSet { SoundEffectController().set(self.iOS_soundEffectsEnabled) }
    }
    #endif

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

    func toInteractiveModel() -> GameViewModel {
        let sge = SnakeGameEnvironmentInteractive(initialGameState: self.gameState)
        return GameViewModel(snakeGameEnvironment: sge)
    }

    func restartGame() {
        gameState = snakeGameEnvironment.reset()
        if settingStepMode.value == .stepAuto {
            start()
        }
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
        guard isPlaying else {
            log.debug("Stop repeatForever, since it has been paused.")
            return
        }
        guard isStepPossible_botsOnly else {
            log.debug("Stop repeatForever, since there is nothing meaningful to be repeated.")
            isPlaying = false
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

        if settingStepMode.value == .stepAuto {
            start()
        }
    }

    func ingameView_playableMode_onDisappear() {
        log.debug("onDisappear")
        isPlaying = false
    }

    func pauseSheet_continueGame() {
        log.debug("continueGame")

        if settingStepMode.value == .stepAuto {
            start()
        }
    }

    func start() {
        guard !isPlaying else {
            log.debug("already busy playing.")
            return
        }
        isPlaying = true
        repeatForever_step_botsOnly()
    }

    func stop() {
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            settingStepMode.set(SettingStepModeValue.stepManual)
            stop()
        } else {
            settingStepMode.set(SettingStepModeValue.stepAuto)
            start()
        }
    }

    func singleStep_botsOnly() {
        settingStepMode.set(SettingStepModeValue.stepManual)
        isPlaying = false
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
        guard let newGameState = snakeGameEnvironment.undo() else {
            log.debug("Reached the beginning of the history. There is nothing that can be undone.")
            return
        }
        gameState = newGameState
    }

    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        switch event {
        case .showLevelSelector:
            player1Info = ""
            player2Info = ""
            player1Length = 0
            player2Length = 0
            showPauseButton = false
        case let .showLevelDetail(gameState):
            player1Info = gameState.player1.humanReadableRole
            player2Info = gameState.player2.humanReadableRole
            player1Length = gameState.player1.lengthOfInstalledSnake()
            player2Length = gameState.player2.lengthOfInstalledSnake()
        case let .beginNewGame(gameState):
            player1Info = gameState.player1.humanReadableRole
            player2Info = gameState.player2.humanReadableRole
            player1Length = gameState.player1.lengthOfInstalledSnake()
            player2Length = gameState.player2.lengthOfInstalledSnake()
            showPauseButton = true
        case let .player1_didUpdateLength(length):
            player1Length = length
        case let .player2_didUpdateLength(length):
            player2Length = length
        case let .player1_dead(causesOfDeath):
            let deathExplanations: [String] = causesOfDeath.map { $0.humanReadableDeathExplanation }
            let info: String = deathExplanations.joined(separator: "\n-\n")
            player1Info = info
        case let .player2_dead(causesOfDeath):
            let deathExplanations: [String] = causesOfDeath.map { $0.humanReadableDeathExplanation }
            let info: String = deathExplanations.joined(separator: "\n-\n")
            player2Info = info
        }
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
