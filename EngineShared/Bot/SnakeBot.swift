// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public protocol SnakeBotInfo {
    /// A version4 UUID that uniquely identifies the bot.
    /// This uuid is saved to userdefaults, so that the same player-configuration can be retrieved later.
    ///
    /// For generating a new uuid, use an online tool.
    /// https://www.uuidgenerator.net/
    var id: UUID { get }

    var humanReadableName: String { get }
}

public protocol SnakeBot: class {
	static var info: SnakeBotInfo { get }
	init()
	func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> SnakeBot

    /// The first element is the current head position
    /// The second element is be the first computed position (near future)
    /// The following elements have lower and lower confidence (far out future).
    var plannedPath: [IntVec2] { get }

    /// The computed move for the player to take
    var plannedMovement: SnakeBodyMovement { get }
}

internal class SnakeBotInfoImpl: SnakeBotInfo {
    let id: UUID
	let humanReadableName: String

	init(id: UUID, humanReadableName: String) {
        self.id = id
		self.humanReadableName = humanReadableName
	}
}


public class SnakeBotFactory {
	public static let snakeBotTypes: [SnakeBot.Type] = [
//		SnakeBot_MoveForward.self,
		SnakeBot1.self,
		SnakeBot4.self,
		SnakeBot5.self,
		SnakeBot6.self,
        SnakeBot7.self,
	]

	public static func emptyBotType() -> SnakeBot.Type {
		return SnakeBot_MoveForward.self
	}

    /// The bot that currently outperforms the other bots, in most scenarios.
    public static func smartestBotType() -> SnakeBot.Type {
        return SnakeBot6.self
    }
}
