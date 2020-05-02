// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakePlayerId {
    case player1
    case player2
}

public class SnakePlayer {
    public let id: SnakePlayerId
    public let isInstalled: Bool
	public let isAlive: Bool
	public let role: SnakePlayerRole
	public let snakeBody: SnakeBody
	public let pendingMovement: SnakeBodyMovement
	public let pendingAct: SnakeBodyAct
    public let causesOfDeath: [SnakeCauseOfDeath]
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

    private init(id: SnakePlayerId, isInstalled: Bool, isAlive: Bool, role: SnakePlayerRole, snakeBody: SnakeBody, pendingMovement: SnakeBodyMovement, pendingAct: SnakeBodyAct, causesOfDeath: [SnakeCauseOfDeath], bot: SnakeBot) {
        self.id = id
        self.isInstalled = isInstalled
		self.isAlive = isAlive
		self.role = role
		self.snakeBody = snakeBody
		self.pendingMovement = pendingMovement
		self.pendingAct = pendingAct
        self.causesOfDeath = causesOfDeath
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
            causesOfDeath: [],
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
            causesOfDeath: causesOfDeath,
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
            causesOfDeath: causesOfDeath,
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
            causesOfDeath: causesOfDeath,
			bot: bot
		)
	}

    /// Examples of how the snake can die: stuck, collision with wall, collision with self, collision with opponent.
    public func kill(_ causeOfDeath: SnakeCauseOfDeath) -> SnakePlayer {
		return SnakePlayer(
            id: id,
            isInstalled: isInstalled,
			isAlive: false,
			role: role,
			snakeBody: snakeBody,
			pendingMovement: pendingMovement,
			pendingAct: pendingAct,
            causesOfDeath: causesOfDeath + [causeOfDeath],
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
            causesOfDeath: causesOfDeath,
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
            causesOfDeath: causesOfDeath,
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
            causesOfDeath: causesOfDeath,
			bot: newBot
		)
	}
}

extension SnakePlayer: CustomDebugStringConvertible {
	public var debugDescription: String {
		let botDescription = String(describing: bot)
        let installed: String = isInstalled ? "installed" : "notinstalled"
        let alive: String = isAlive ? "alive" : "dead"
		return "SnakePlayer(\(id), \(installed), \(alive), \(snakeBody.head.position), \(snakeBody.head.direction), \(pendingMovement), \(pendingAct), \(causesOfDeath), \(role), \(botDescription))"
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
        }
    }
}
