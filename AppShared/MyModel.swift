// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import Combine
import SwiftUI

public class MyModel: ObservableObject {
    public let jumpToLevelSelector = PassthroughSubject<Void, Never>()
    @Published var player1Length: UInt = 1
    @Published var player2Length: UInt = 1

    func sendInfoEvent(_ event: SnakeGameInfoEvent) {
        switch event {
        case .showLevelSelector:
            player1Length = 0
            player2Length = 0
//            if !parent.isPreview {
//                parent.player1Info = ""
//                parent.player2Info = ""
//                parent.player1Length = 0
//                parent.player2Length = 0
//            }
        case let .showLevelDetail(gameState):
//            parent.player1Info = gameState.player1.humanReadableRole
//            parent.player2Info = gameState.player2.humanReadableRole
            player1Length = gameState.player1.lengthOfInstalledSnake()
            player2Length = gameState.player2.lengthOfInstalledSnake()
        case let .beginNewGame(gameState):
//            parent.player1Info = gameState.player1.humanReadableRole
//            parent.player2Info = gameState.player2.humanReadableRole
            player1Length = gameState.player1.lengthOfInstalledSnake()
            player2Length = gameState.player2.lengthOfInstalledSnake()
        case let .player1_didUpdateLength(length):
            player1Length = length
        case let .player2_didUpdateLength(length):
            player2Length = length
        case let .player1_killed(killEvents):
            let deathExplanations: [String] = killEvents.map { $0.humanReadableDeathExplanation }
            let info: String = deathExplanations.joined(separator: "\n-\n")
//            parent.player1Info = info
        case let .player2_killed(killEvents):
            let deathExplanations: [String] = killEvents.map { $0.humanReadableDeathExplanation }
            let info: String = deathExplanations.joined(separator: "\n-\n")
//            parent.player2Info = info
        }
    }

}
