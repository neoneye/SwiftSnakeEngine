// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public protocol SnakeBotInfo {
	var humanReadableName: String { get }
	var userDefaultIdentifier: String { get }
}

public protocol SnakeBot: class {
	static var info: SnakeBotInfo { get }
	init()
	func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> (SnakeBot, SnakeBodyMovement)
	func plannedPath() -> [IntVec2]
}

internal class SnakeBotInfoImpl: SnakeBotInfo {
	let humanReadableName: String
	let userDefaultIdentifier: String

	init(humanReadableName: String, userDefaultIdentifier: String) {
		self.humanReadableName = humanReadableName
		self.userDefaultIdentifier = userDefaultIdentifier
	}
}


public class SnakeBotFactory {
	public static let snakeBotTypes: [SnakeBot.Type] = [
//		SnakeBot_MoveForward.self,
		SnakeBot1.self,
		SnakeBot4.self,
		SnakeBot5.self,
		SnakeBot6.self
	]

	public static func emptyBotType() -> SnakeBot.Type {
		return SnakeBot_MoveForward.self
	}
}
