// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakePlayerRole {
    case none
    case human
    case bot(snakeBotType: SnakeBot.Type)
}

extension SnakePlayerRole {
    public var id: UUID {
        switch self {
        case .none:
            return UUID(uuidString: "a036c9e1-ca00-46f5-a960-16451d66390e")!
        case .human:
            return UUID(uuidString: "c7ccdf6d-56ac-491c-857b-be6a80bc6598")!
        case .bot(let snakeBotType):
            return snakeBotType.info.id
        }
    }
}

extension SnakePlayerRole: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.id.hash(into: &hasher)
    }
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

extension SnakePlayerRole {
    public static func create(uuid: UUID) -> SnakePlayerRole? {
        if uuid == SnakePlayerRole.none.id {
            return SnakePlayerRole.none
        }
        if uuid == SnakePlayerRole.human.id {
            return SnakePlayerRole.human
        }
        if let botType: SnakeBot.Type = SnakeBotFactory.shared.botType(for: uuid) {
            return SnakePlayerRole.bot(snakeBotType: botType)
        }
        return nil
    }
}
