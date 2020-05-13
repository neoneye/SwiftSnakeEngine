// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import Combine

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

class LevelSelectorDataSource {
    static func createGameStatesWithUserDefaults() -> [SnakeGameState] {
        let role1: SnakePlayerRole
        let role2: SnakePlayerRole
        #if os(macOS)
        role1 = SettingPlayer1Role().value
        role2 = SettingPlayer2Role().value
        #else
        role1 = SnakePlayerRole.human
        let playerMode: PlayerMode = PlayerModeController().value
        switch playerMode {
        case .twoPlayer_humanBot:
            let snakeBotType: SnakeBot.Type = SnakeBotFactory.smartestBotType()
            role2 = SnakePlayerRole.bot(snakeBotType: snakeBotType)
        case .singlePlayer_human:
           role2 = SnakePlayerRole.none
        }
        #endif
        return createGameStates(role1: role1, role2: role2)
    }

    static func createGameStates(role1: SnakePlayerRole, role2: SnakePlayerRole) -> [SnakeGameState] {
        let levelNames: [String] = SnakeLevelManager.shared.levelNames
        return levelNames.map {
            SnakeGameState.create(player1: role1, player2: role2, levelName: $0)
        }
    }
}
