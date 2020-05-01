// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakePlayerRole {
    case none
    case human
    case bot(snakeBotType: SnakeBot.Type)
}

extension SnakePlayerRole: Equatable {
    public static func == (lhs: SnakePlayerRole, rhs: SnakePlayerRole) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.human, .human):
            return true
        case let (.bot(bot0), .bot(bot1)):
            let isEqual_snakeBotType: Bool = bot0 == bot1
            return isEqual_snakeBotType
        default:
            return false
        }
    }
}
