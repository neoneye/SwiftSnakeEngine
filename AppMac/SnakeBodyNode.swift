// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame

class SnakeBodyNode: SKEffectNode {
	var drawLines: Bool = true
	var lineWidth: CGFloat = 1
	var strokeColor: SKColor = SKColor.black
	var botPlannedPathColor: SKColor = SKColor.darkGray
	var botPlannedPathLineWidthThick: CGFloat = 20
	var botPlannedPathLineWidthThin: CGFloat = 1

	var node_snakeHeadUp: SKSpriteNode?
	var node_snakeHeadLeft: SKSpriteNode?
	var node_snakeHeadRight: SKSpriteNode?
	var node_snakeHeadDown: SKSpriteNode?
	var node_snakeBody: SKSpriteNode?
	var node_snakeFood: SKSpriteNode?

	typealias CoordinateConverter = (IntVec2) -> CGPoint
	var convertCoordinate: CoordinateConverter?

	func convert(_ position: IntVec2) -> CGPoint {
		return convertCoordinate?(position) ?? CGPoint.zero
	}

	public func configure(skin: PlayerSkinMenuItem) {
		switch skin {
		case .retroGreen:
			let colorGreen: SKColor = SKColor(named: "snakeskin_simple_green") ?? SKColor.green
			loadSimpleAtlas(named: "snakeskin_simple", color: colorGreen)
		case .retroBlue:
			let colorBlue: SKColor = SKColor(named: "snakeskin_simple_blue") ?? SKColor.blue
			loadSimpleAtlas(named: "snakeskin_simple", color: colorBlue)
		case .cuteGreen:
			loadFullAtlas(named: "snakeskin_green")
		case .cuteBlue:
			loadFullAtlas(named: "snakeskin_blue")
		}
	}

	private func loadFullAtlas(named: String) {
		self.strokeColor = SKColor.black
		self.drawLines = true
		self.lineWidth = 40
		let atlas = SKTextureAtlas(named: named)

		func load(_ textureName: String) -> SKSpriteNode {
			let texture = atlas.textureNamed(textureName)
			return SKSpriteNode(texture: texture)
		}
		self.node_snakeHeadUp = load("head_up")
		self.node_snakeHeadLeft = load("head_left")
		self.node_snakeHeadRight = load("head_right")
		self.node_snakeHeadDown = load("head_down")
		self.node_snakeBody = load("body_empty")
		self.node_snakeFood = load("body_food")

		self.node_snakeBody?.setScale(0.7)
	}

	private func loadSimpleAtlas(named: String, color: SKColor) {
		self.strokeColor = color
		self.drawLines = true
		self.lineWidth = 90
		let atlas = SKTextureAtlas(named: named)

		func load(_ textureName: String) -> SKSpriteNode {
			let texture = atlas.textureNamed(textureName)
			let node = SKSpriteNode(texture: texture)
			node.color = color
			node.colorBlendFactor = 1
			return node
		}
		self.node_snakeHeadUp = load("head")
		self.node_snakeHeadLeft = load("head")
		self.node_snakeHeadRight = load("head")
		self.node_snakeHeadDown = load("head")
		self.node_snakeBody = load("body")
		self.node_snakeFood = load("body")
	}

	func rebuild(player: SnakePlayer) {
		guard player.isInstalled else {
			//log.debug("do nothing, since the player is not installed, and thus not shown")
			return
		}

		self.removeAllChildren()

		drawPlannedPathForBot(player)
		drawPendingMovementForHuman(player)

		let snakeBody: SnakeBody = player.snakeBody

		// Draw lines between the body parts
		let positionArray: [IntVec2] = snakeBody.positionArray()
		if drawLines && positionArray.count >= 2 {
			var range: Range = positionArray.indices
			range.removeLast()
			for i in range {
				let position0: IntVec2 = positionArray[i]
				let position1: IntVec2 = positionArray[i + 1]
				let yourline = SKShapeNode()
				let pathToDraw = CGMutablePath()
				pathToDraw.move(to: convert(position0))
				pathToDraw.addLine(to: convert(position1))
				yourline.path = pathToDraw
				yourline.strokeColor = strokeColor
				yourline.lineWidth = lineWidth
				self.addChild(yourline)
			}
		}

		// Draw the head
		if let n = snakeHead(direction: snakeBody.head.direction)?.copy() as? SKSpriteNode {
			n.position = convert(snakeBody.head.position)
			n.isHidden = false
			self.addChild(n)
		}

		// Draw the body parts
		if snakeBody.fifo.array.count >= 1 {
			var range: Range = snakeBody.fifo.array.indices
			// Except don't draw the head
			range.removeLast()
			for i in range {
				let bodyPart: SnakeBodyPart = snakeBody.fifo.array[i]
				switch bodyPart.content {
				case .food:
					if let n = self.node_snakeFood?.copy() as? SKSpriteNode {
						n.position = convert(bodyPart.position)
						n.isHidden = false
						self.addChild(n)
					}
				case .empty:
					if let n = self.node_snakeBody?.copy() as? SKSpriteNode {
						n.position = convert(bodyPart.position)
						n.isHidden = false
						self.addChild(n)
					}
				}
			}
		}

		if player.isAlive {
			self.alpha = 1
		} else {
			self.alpha = 0.25
		}
	}

	private func drawPlannedPathForBot(_ player: SnakePlayer) {
		let showPlannedPath: Bool = NSUserDefaultsController.shared.isShowPlannedPathEnabled
        if showPlannedPath && player.isBot && player.isAlive {
			let positionArray: [IntVec2] = player.bot.plannedPath()
			drawPlannedPath(positionArray)
		}
	}

	private func drawPendingMovementForHuman(_ player: SnakePlayer) {
		if player.role == .human {
			// When there are 2 human players and there is no time-constraint,
			// then it's difficult to tell if player1 is waiting for player2 or the other way around.
			// A small hint here is to show the pending move of the fastest player.
			// This way it's possible to see who is ready and who needs to make a move.
			let pendingMovement: SnakeBodyMovement = player.pendingMovement
			switch pendingMovement {
			case .dontMove:
				()
			case .moveForward, .moveCCW, .moveCW:
				let head0: SnakeHead = player.snakeBody.head
				let head1: SnakeHead = head0.simulateTick(movement: pendingMovement)
				let positionArray: [IntVec2] = [head0.position, head1.position]
				drawPlannedPath(positionArray)
			}
		}
	}

	private func drawPlannedPath(_ positionArray: [IntVec2]) {
		let positionArrayCount: Int = positionArray.count
		guard positionArrayCount >= 2 else {
			//log.debug("Cannot show the planned path, it's too short.")
			return
		}
		let positionArrayCountMinus1: Int = positionArrayCount - 1
		for i in 0..<positionArrayCountMinus1 {
			let position0: IntVec2 = positionArray[i]
			let position1: IntVec2 = positionArray[i + 1]
			let yourline = SKShapeNode()
			let pathToDraw = CGMutablePath()
			pathToDraw.move(to: convert(position0))
			pathToDraw.addLine(to: convert(position1))
			yourline.path = pathToDraw
			yourline.strokeColor = botPlannedPathColor
			yourline.lineWidth = remap(
				CGFloat(i),
				CGFloat(0),
				CGFloat(positionArrayCountMinus1),
				CGFloat(botPlannedPathLineWidthThick),
				CGFloat(botPlannedPathLineWidthThin)
			)
			self.addChild(yourline)
		}
	}

	private func snakeHead(direction: SnakeHeadDirection) -> SKSpriteNode? {
		switch direction {
		case .up:
			return node_snakeHeadUp
		case .left:
			return node_snakeHeadLeft
		case .right:
			return node_snakeHeadRight
		case .down:
			return node_snakeHeadDown
		}
	}
}
