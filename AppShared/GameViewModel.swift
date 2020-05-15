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

    private var pendingMovement_player1: SnakeBodyMovement = .dontMove
    private var pendingMovement_player2: SnakeBodyMovement = .dontMove

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
    }

    #if os(iOS)
    @Published var iOS_soundEffectsEnabled: Bool = SoundEffectController().value {
        didSet { SoundEffectController().set(self.iOS_soundEffectsEnabled) }
    }
    #endif

    init(snakeGameEnvironment: SnakeGameEnvironment) {
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

    func toInteractiveModel() -> GameViewModel {
        let sge = SnakeGameEnvironmentInteractive(initialGameState: self.gameState)
        return GameViewModel(snakeGameEnvironment: sge)
    }

    func restartGame() {
        gameState = snakeGameEnvironment.reset()
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
//            userInput_stepBackwardOnce_ifSingleHuman()
            return
        }
        switch player.id {
        case .player1:
            pendingMovement_player1 = movement
        case .player2:
            pendingMovement_player2 = movement
        }
//        self.isPaused = false
//        self.pendingUpdateAction = .stepForwardContinuously
        stepForward()
    }

    func singleStepForwardOnlyForBots() {
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
            log.debug("Single step forward can only be done when there are only bots")
            return
        }
        stepForward()
    }

    private func stepForward() {
        // IDEA: perform in a separate thread
        let action = SnakeGameAction(
            player1: pendingMovement_player1,
            player2: pendingMovement_player2
        )
        let newGameState = snakeGameEnvironment.step(action: action)
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
