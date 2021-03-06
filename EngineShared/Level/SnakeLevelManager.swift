// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeLevelManager {
	public static let shared = SnakeLevelManager()

	private var nameToLevel = [String: SnakeLevel]()
    private var idToLevel = [UUID: SnakeLevel]()

	public let levelNames: [String]
	public let defaultLevelName: String

	private init() {
		let levelNames: [String] = [
			"Level 0.csv",
			//"Level 1.csv", // Too huge for the AI to complete a round in reasonable time.
			"Level 2.csv",
			"Level 3.csv",
			//"Level 4.csv", // Requires 2 players. Unsuitable for single player games.
			//"Level 5.csv", // Requires 2 players. Unsuitable for single player games.
			"Level 6.csv",
			"Level 7.csv",
			"Level 8.csv",
            "Level 9.csv",
            "Level 10.csv",
            "Level 11.csv",
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

            let levelId: UUID = snakeLevel.id
            self.idToLevel[levelId] = snakeLevel
		}
	}

	public func level(name: String) -> SnakeLevel? {
		return nameToLevel[name]
	}

    public func level(id: UUID) -> SnakeLevel? {
        return idToLevel[id]
    }
}
