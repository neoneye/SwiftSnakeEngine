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

public enum SnakePlayerKillEvent {
    case collisionWithWall
    case collisionWithItself
    case collisionWithOpponent
    case noMoreFood
    case stuckInALoop
    case killAfterAFewTimeSteps
}

public class SnakePlayer {
	public let isAlive: Bool
	public let isInstalled: Bool
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

	private init(isAlive: Bool, isInstalled: Bool, role: SnakePlayerRole, snakeBody: SnakeBody, pendingMovement: SnakeBodyMovement, pendingAct: SnakeBodyAct, killEvents: [SnakePlayerKillEvent], bot: SnakeBot) {
		self.isAlive = isAlive
		self.isInstalled = isInstalled
		self.role = role
		self.snakeBody = snakeBody
		self.pendingMovement = pendingMovement
		self.pendingAct = pendingAct
        self.killEvents = killEvents
		self.bot = bot
	}

	public class func create(role: SnakePlayerRole) -> SnakePlayer {
		let snakeBotType: SnakeBot.Type
		switch role {
		case .none:
			snakeBotType = SnakeBotFactory.emptyBotType()
		case .human:
			snakeBotType = SnakeBotFactory.emptyBotType()
		case let .bot(snakeBotType2):
			snakeBotType = snakeBotType2
		}

		let bot: SnakeBot = snakeBotType.init()

		return SnakePlayer(
			isAlive: true,
			isInstalled: true,
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
			isAlive: isAlive,
			isInstalled: isInstalled,
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
			isAlive: isAlive,
			isInstalled: isInstalled,
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
			isAlive: isAlive,
			isInstalled: isInstalled,
			role: role,
			snakeBody: snakeBody,
			pendingMovement: .dontMove,
			pendingAct: .doNothing,
            killEvents: killEvents,
			bot: bot
		)
	}

    // IDEA: add a kill reason, such as: stuck, collision with wall, collision with self, collision with opponent.
    public func kill(_ killEvent: SnakePlayerKillEvent) -> SnakePlayer {
		return SnakePlayer(
			isAlive: false,
			isInstalled: isInstalled,
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
			isAlive: false,
			isInstalled: false,
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
			isAlive: isAlive,
			isInstalled: isInstalled,
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
			isAlive: isAlive,
			isInstalled: isInstalled,
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
		return "\(snakeBody.head.position) \(snakeBody.head.direction) \(botDescription) \(pendingMovement) \(pendingAct)"
	}
}
