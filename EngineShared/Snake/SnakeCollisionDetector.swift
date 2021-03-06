// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakeCollisionType {
	case noCollision
	case snakeCollisionWithWall
	case snakeCollisionWithOpponent
	case snakeCollisionWithItself
}

public class SnakeCollisionDetector {
	private let level: SnakeLevel
	private let foodPosition: IntVec2?
	private let player1Body: SnakeBody
	private let player2Body: SnakeBody
	private let player1Installed: Bool
	private let player2Installed: Bool
	public private(set) var player1Alive: Bool
	public private(set) var player2Alive: Bool
	public private(set) var player1EatsFood: Bool
	public private(set) var player2EatsFood: Bool
	public private(set) var collisionType1: SnakeCollisionType
	public private(set) var collisionType2: SnakeCollisionType

	public class func create(level: SnakeLevel, foodPosition: IntVec2?, player1: SnakePlayer, player2: SnakePlayer) -> SnakeCollisionDetector {
		let player1Installed: Bool = player1.isInstalled
		let player2Installed: Bool = player2.isInstalled
		let player1Alive: Bool = player1.isInstalledAndAlive
		let player2Alive: Bool = player2.isInstalledAndAlive

		func stateForTick(_ player: SnakePlayer) -> SnakeBody {
			let movement: SnakeBodyMovement
            if player.isInstalledAndAlive {
				movement = player.pendingMovement
			} else {
				movement = .dontMove
			}
			return player.snakeBody.stateForTick(movement: movement, act: .doNothing)
		}

		let player1Body: SnakeBody = stateForTick(player1)
		let player2Body: SnakeBody = stateForTick(player2)

		return SnakeCollisionDetector(
			level: level,
			foodPosition: foodPosition,
			player1Installed: player1Installed,
			player2Installed: player2Installed,
			player1Body: player1Body,
			player2Body: player2Body,
			player1Alive: player1Alive,
			player2Alive: player2Alive
		)
	}

	public init(level: SnakeLevel, foodPosition: IntVec2?, player1Installed: Bool, player2Installed: Bool, player1Body: SnakeBody, player2Body: SnakeBody, player1Alive: Bool, player2Alive: Bool) {
		self.level = level
		self.foodPosition = foodPosition
		self.player1Installed = player1Installed
		self.player2Installed = player2Installed
		self.player1Body = player1Body
		self.player2Body = player2Body
		self.player1Alive = player1Alive
		self.player2Alive = player2Alive
		self.player1EatsFood = false
		self.player2EatsFood = false
		self.collisionType1 = .noCollision
		self.collisionType2 = .noCollision
	}

    /// This function is fragile. If provided with garbage input, then it wont be
    /// able to detect collisions.
    ///
	/// Deal with collision when both the player1 and the player2 is installed.
	/// Deal with collision only if either the player1 or player2 is installed.
    ///
    /// This function only considers the head of the snake.
    /// The remaining snake body parts are not being checked for collision.
    /// It's time consuming to do a full collision detection, and hard to tell what went wrong.
    /// It's much faster only to consider the snake head and easier to tell what kind of collision happened.
    /// However this also makes it fragile to garbage input data.
	public func process() {
        guard player1Installed || player2Installed else {
            log.debug("None of the players are installed. No need for checking for collisons.")
            return
        }
		guard player1Alive || player2Alive else {
			//log.debug("Both players are dead. No need to check for collision between them. 1")
			return
		}

		func kill1(_ collisionType: SnakeCollisionType) {
			player1Alive = false
			collisionType1 = collisionType
		}

		func kill2(_ collisionType: SnakeCollisionType) {
			player2Alive = false
			collisionType2 = collisionType
		}

		if player1Installed && player1Alive {
			let wallCollision: Bool = level.getValue(player1Body.head.position) == .wall
			if wallCollision {
				//log.debug("player1 collided with wall")
				kill1(.snakeCollisionWithWall)
			}
		}
		if player2Installed && player2Alive {
			let wallCollision: Bool = level.getValue(player2Body.head.position) == .wall
			if wallCollision {
				//log.debug("player2 collided with wall")
				kill2(.snakeCollisionWithWall)
			}
		}
		guard player1Alive || player2Alive else {
			//log.debug("both players are dead. No need for doing more collision detection. 2")
			return
		}

		if player1Installed && player2Installed && player1Alive && player2Alive {
			let directHeadCollision: Bool = player1Body.head.position == player2Body.head.position
			if directHeadCollision {
				//log.debug("direct head collision between players. mutual destruction!")
				kill1(.snakeCollisionWithOpponent)
				kill2(.snakeCollisionWithOpponent)
				return
			}
		}

        if player1Installed && player2Installed {
            let positions1: Set<IntVec2> = player1Body.positionSet()
            let positions2: Set<IntVec2> = player2Body.positionSet()

            if player1Alive {
                let opponentCollision: Bool = positions2.contains(player1Body.head.position)
                if opponentCollision {
                    //log.debug("player1 collided with opponent snake")
                    kill1(.snakeCollisionWithOpponent)
                }
            }
            if player2Alive {
                let opponentCollision: Bool = positions1.contains(player2Body.head.position)
                if opponentCollision {
                    //log.debug("player2 collided with opponent snake")
                    kill2(.snakeCollisionWithOpponent)
                }
            }
        }
		guard player1Alive || player2Alive else {
			//log.debug("both players are dead. No need for doing more collision detection. 3")
			return
		}

		if player1Installed && player1Alive && player1Body.isEatingItself {
			//log.debug("snake1 collided with itself")
			kill1(.snakeCollisionWithItself)
		}
		if player2Installed && player2Alive && player2Body.isEatingItself {
			//log.debug("snake2 collided with itself")
			kill2(.snakeCollisionWithItself)
		}
		guard player1Alive || player2Alive else {
			//log.debug("both players are dead. No need for doing more collision detection. 4")
			return
		}

		//log.debug("success. detected no collision")

		if let foodPosition = self.foodPosition {
			if player1Installed && player1Alive && player1Body.head.position == foodPosition {
				//log.debug("player1 eats food")
				self.player1EatsFood = true
			}
			if player2Installed && player2Alive && player2Body.head.position == foodPosition {
				//log.debug("player2 eats food")
				self.player2EatsFood = true
			}
		}
	}
}

extension SnakeGameState {

    /// Deal with collision when one player or both players are installed.
    /// Do nothing when no players are installed.
    internal func detectCollision() -> SnakeGameState {
        let player1_installedAndAlive: Bool = self.player1.isInstalledAndAlive
        let player2_installedAndAlive: Bool = self.player2.isInstalledAndAlive

        guard player1_installedAndAlive || player2_installedAndAlive else {
            log.debug("Both players are dead. No need to check for collision between them. 1")
            return self
        }
        var gameState: SnakeGameState = self

        let detector = SnakeCollisionDetector.create(
            level: gameState.level,
            foodPosition: gameState.foodPosition,
            player1: gameState.player1,
            player2: gameState.player2
        )
        detector.process()

        if player1_installedAndAlive && detector.player1Alive == false {
            let collisionType: SnakeCollisionType = detector.collisionType1
            log.info("killing player1 because: \(collisionType)")
            gameState = gameState.killPlayer1(collisionType.causeOfDeath)
        }
        if player2_installedAndAlive && detector.player2Alive == false {
            let collisionType: SnakeCollisionType = detector.collisionType2
            log.info("killing player2 because: \(collisionType)")
            gameState = gameState.killPlayer2(collisionType.causeOfDeath)
        }

        if detector.player1EatsFood {
            gameState = gameState.stateWithNewFoodPosition(nil)
            var player: SnakePlayer = gameState.player1
            player = player.updatePendingAct(.eat)
            gameState = gameState.stateWithNewPlayer1(player)
        }
        if detector.player2EatsFood {
            gameState = gameState.stateWithNewFoodPosition(nil)
            var player: SnakePlayer = gameState.player2
            player = player.updatePendingAct(.eat)
            gameState = gameState.stateWithNewPlayer2(player)
        }
        return gameState
    }
}

extension SnakeCollisionType {
    /// Convert from a `CollisionType` to its corresponding `CauseOfDeath`.
    internal var causeOfDeath: SnakeCauseOfDeath {
        switch self {
        case .noCollision:
            fatalError("Inconsistency. A collision happened, but no collision is registered. Should never happen!")
        case .snakeCollisionWithWall:
            return .collisionWithWall
        case .snakeCollisionWithOpponent:
            return .collisionWithOpponent
        case .snakeCollisionWithItself:
            return .collisionWithItself
        }
    }
}
