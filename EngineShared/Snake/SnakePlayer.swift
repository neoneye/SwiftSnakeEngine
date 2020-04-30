// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakePlayerRole {
	case none
	case human
	case bot(snakeBotType: SnakeBot.Type)
    case replay
}

public enum SnakePlayerId {
    case player1
    case player2
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
        case (.replay, .replay):
            return true
		default:
			return false
		}
	}
}

public class SnakePlayer {
    public let id: SnakePlayerId
    public let isInstalled: Bool
	public let isAlive: Bool
	public let role: SnakePlayerRole
	public let snakeBody: SnakeBody
	public let pendingMovement: SnakeBodyMovement
	public let pendingAct: SnakeBodyAct
    public let killEvents: [SnakePlayerKillEvent]
	public let bot: SnakeBot

	public var isDead: Bool {
		return !isAlive
	}

	public var isBot: Bool {
		switch role {
		case .none:
			return false
		case .human:
			return false
		case .bot:
			return true
        case .replay:
            return false
		}
	}

    /// Length of snake body.
    ///
    /// - Returns:
    ///     - The length of the snake if it's installed. No matter if it's alive or dead.
    ///     - Zero if there player isn't installed.
    public func lengthOfInstalledSnake() -> UInt {
        guard isInstalled else {
            return 0
        }
        return snakeBody.length
    }

    private init(id: SnakePlayerId, isInstalled: Bool, isAlive: Bool, role: SnakePlayerRole, snakeBody: SnakeBody, pendingMovement: SnakeBodyMovement, pendingAct: SnakeBodyAct, killEvents: [SnakePlayerKillEvent], bot: SnakeBot) {
        self.id = id
        self.isInstalled = isInstalled
		self.isAlive = isAlive
		self.role = role
		self.snakeBody = snakeBody
		self.pendingMovement = pendingMovement
		self.pendingAct = pendingAct
        self.killEvents = killEvents
		self.bot = bot
	}

	public class func create(id: SnakePlayerId, role: SnakePlayerRole) -> SnakePlayer {
		let snakeBotType: SnakeBot.Type
		switch role {
		case .none:
			snakeBotType = SnakeBotFactory.emptyBotType()
		case .human:
			snakeBotType = SnakeBotFactory.emptyBotType()
		case let .bot(snakeBotType2):
			snakeBotType = snakeBotType2
        case .replay:
            snakeBotType = SnakeBotFactory.emptyBotType()
		}

		let bot: SnakeBot = snakeBotType.init()

		return SnakePlayer(
            id: id,
            isInstalled: true,
			isAlive: true,
			role: role,
			snakeBody: SnakeBody.create(position: IntVec2.zero, headDirection: .right, length: 1),
			pendingMovement: .dontMove,
			pendingAct: .doNothing,
            killEvents: [],
			bot: bot
		)
	}

	public func updatePendingMovement(_ newPendingMovement: SnakeBodyMovement) -> SnakePlayer {
		return SnakePlayer(
            id: id,
            isInstalled: isInstalled,
			isAlive: isAlive,
			role: role,
			snakeBody: snakeBody,
			pendingMovement: newPendingMovement,
			pendingAct: pendingAct,
            killEvents: killEvents,
			bot: bot
		)
	}

	public func updatePendingAct(_ newPendingAct: SnakeBodyAct) -> SnakePlayer {
		return SnakePlayer(
            id: id,
            isInstalled: isInstalled,
			isAlive: isAlive,
			role: role,
			snakeBody: snakeBody,
			pendingMovement: pendingMovement,
			pendingAct: newPendingAct,
            killEvents: killEvents,
			bot: bot
		)
	}

	public func clearPendingMovementAndPendingActForHuman() -> SnakePlayer {
		guard role == .human else {
			return self
		}
		return SnakePlayer(
            id: id,
            isInstalled: isInstalled,
			isAlive: isAlive,
			role: role,
			snakeBody: snakeBody,
			pendingMovement: .dontMove,
			pendingAct: .doNothing,
            killEvents: killEvents,
			bot: bot
		)
	}

    /// Examples of how the snake can die: stuck, collision with wall, collision with self, collision with opponent.
    public func kill(_ killEvent: SnakePlayerKillEvent) -> SnakePlayer {
		return SnakePlayer(
            id: id,
            isInstalled: isInstalled,
			isAlive: false,
			role: role,
			snakeBody: snakeBody,
			pendingMovement: pendingMovement,
			pendingAct: pendingAct,
            killEvents: killEvents + [killEvent],
			bot: bot
		)
	}

	public func uninstall() -> SnakePlayer {
		return SnakePlayer(
            id: id,
            isInstalled: false,
			isAlive: false,
			role: .none,
			snakeBody: snakeBody,
			pendingMovement: pendingMovement,
			pendingAct: pendingAct,
            killEvents: killEvents,
			bot: bot
		)
	}

	public func playerWithNewSnakeBody(_ newSnakeBody: SnakeBody) -> SnakePlayer {
		return SnakePlayer(
            id: id,
            isInstalled: isInstalled,
			isAlive: isAlive,
			role: role,
			snakeBody: newSnakeBody,
			pendingMovement: pendingMovement,
			pendingAct: pendingAct,
            killEvents: killEvents,
			bot: bot
		)
	}

	public func updateBot(_ newBot: SnakeBot) -> SnakePlayer {
		return SnakePlayer(
            id: id,
            isInstalled: isInstalled,
			isAlive: isAlive,
			role: role,
			snakeBody: snakeBody,
			pendingMovement: pendingMovement,
			pendingAct: pendingAct,
            killEvents: killEvents,
			bot: newBot
		)
	}
}

extension SnakePlayer: CustomDebugStringConvertible {
	public var debugDescription: String {
		let botDescription = String(describing: bot)
        let installed: String = isInstalled ? "installed" : "notinstalled"
        let alive: String = isAlive ? "alive" : "dead"
		return "SnakePlayer(\(id), \(installed), \(alive), \(role), \(snakeBody.head.position), \(snakeBody.head.direction), \(botDescription) \(pendingMovement), \(pendingAct), \(killEvents))"
	}
}

extension SnakePlayer {
    public var humanReadableRole: String {
        switch self.role {
        case .none:
            return "Player is disabled"
        case .human:
            switch self.id {
            case .player1:
                return "HUMAN\nControlled via Arrow keys."
            case .player2:
                return "HUMAN\nControlled via WASD keys."
            }
        case let .bot(botType):
            let name: String = botType.self.info.humanReadableName
            return "BOT - \(name)"
        case .replay:
            return "Replay"
        }
    }
}
