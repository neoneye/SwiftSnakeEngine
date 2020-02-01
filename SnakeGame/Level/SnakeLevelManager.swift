// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeLevelManager {
	public static let shared = SnakeLevelManager()

	private var nameToLevel = [String: SnakeLevel]()

	public let levelNames: [String]
	public let defaultLevelName: String

	private init() {
		let levelNames: [String] = [
			"Level 0.csv",
			"Level 1.csv",
			"Level 2.csv",
			"Level 3.csv",
			"Level 4.csv",
			"Level 5.csv",
			"Level 6.csv",
			"Level 7.csv",
			"Level 8.csv",
		]
		self.levelNames = levelNames
		self.defaultLevelName = levelNames.first!
	}

	public class func setup() {
		self.shared.setup()
	}

	private func setup() {
		guard nameToLevel.isEmpty else {
			// already initialized
			return
		}

		for levelName in self.levelNames {
			let snakeLevel: SnakeLevel = SnakeLevel.load(levelName)
			self.nameToLevel[levelName] = snakeLevel
		}
	}

	public func level(_ levelName: String) -> SnakeLevel? {
		return nameToLevel[levelName]
	}
}
