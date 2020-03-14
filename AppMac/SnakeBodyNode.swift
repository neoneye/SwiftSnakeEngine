// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame

class SnakeBodyNode: SKEffectNode {
    enum Theme {
        case retro
        case textured
    }
    var theme = Theme.retro
	var drawLines: Bool = true
	var lineWidth: CGFloat = 1
	var strokeColor: SKColor = SKColor.black

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
			configure_retroTheme(color: colorGreen)
		case .retroBlue:
			let colorBlue: SKColor = SKColor(named: "snakeskin_simple_blue") ?? SKColor.blue
			configure_retroTheme(color: colorBlue)
		case .cuteGreen:
			configure_texturedTheme(named: "snakeskin_green")
		case .cuteBlue:
			configure_texturedTheme(named: "snakeskin_blue")
		}
	}

	private func configure_texturedTheme(named: String) {
        self.theme = Theme.textured
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

	private func configure_retroTheme(color: SKColor) {
        self.theme = Theme.retro
		self.strokeColor = color
		self.drawLines = false
		self.lineWidth = 90
	}

    func rebuild(player: SnakePlayer) {
        switch self.theme {
        case .retro:
            rebuild_retroTheme(player: player)
        case .textured:
            rebuild_texturedTheme(player: player)
        }
    }

    private func rebuild_retroTheme(player: SnakePlayer) {
        guard player.isInstalled else {
            //log.debug("do nothing, since the player is not installed, and thus not shown")
            return
        }

        self.removeAllChildren()

        let snakeBody: SnakeBody = player.snakeBody

        // Draw lines between the body parts
        let positionArray: [IntVec2] = snakeBody.positionArray()
        if positionArray.count >= 2 {
            var range: Range = positionArray.indices
            range.removeLast()
            let pathToDraw = CGMutablePath()
            for i in range {
                let position0: IntVec2 = positionArray[i]
                let position1: IntVec2 = positionArray[i + 1]
                if i == 0 {
                    pathToDraw.move(to: convert(position0))
                }
                pathToDraw.addLine(to: convert(position1))
            }
            let shapeNode = SKShapeNode(path: pathToDraw)
            shapeNode.strokeColor = strokeColor
            shapeNode.lineWidth = 70
            shapeNode.lineCap = .round
            shapeNode.lineJoin = .round
            self.addChild(shapeNode)
        }

        do {
            let size = CGSize(width: 95, height: 95)
            let shapeNode = SKShapeNode(rectOf: size, cornerRadius: 10)
            shapeNode.position = convert(snakeBody.head.position)
            shapeNode.fillColor = strokeColor
            shapeNode.lineWidth = 0
            self.addChild(shapeNode)
        }

        if player.isAlive {
            self.alpha = 1
        } else {
            self.alpha = 0.25
        }
    }

	func rebuild_texturedTheme(player: SnakePlayer) {
		guard player.isInstalled else {
			//log.debug("do nothing, since the player is not installed, and thus not shown")
			return
		}

		self.removeAllChildren()

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
