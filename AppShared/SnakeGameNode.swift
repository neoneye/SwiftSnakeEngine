// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

class SnakeGameNode: SKNode {
	var gameState: SnakeGameState

	override init() {
		self.gameState = SnakeGameState.empty()
		super.init()
	}

	required init?(coder aDecoder: NSCoder) {
		self.gameState = SnakeGameState.empty()
		super.init(coder: aDecoder)
	}

	var node_food: SKSpriteNode?
	var node_wall: SKSpriteNode?
	var node_floor: SKShapeNode?
	var floorColor: SKColor?

	lazy var snakeBodyNode1: SnakeBodyNode = {
		let instance = SnakeBodyNode()
		instance.convertCoordinate = { [weak self] (position) in
			return self?.cgPointFromGridPoint(position) ?? CGPoint.zero
		}
		return instance
	}()

	lazy var snakeBodyNode2: SnakeBodyNode = {
		let instance = SnakeBodyNode()
		instance.convertCoordinate = { [weak self] (position) in
			return self?.cgPointFromGridPoint(position) ?? CGPoint.zero
		}
		return instance
	}()

    lazy var snakePlannedPathNode1: SnakePlannedPathNode = {
        let instance = SnakePlannedPathNode()
        instance.convertCoordinate = { [weak self] (position) in
            return self?.cgPointFromGridPoint(position) ?? CGPoint.zero
        }
        return instance
    }()

    lazy var snakePlannedPathNode2: SnakePlannedPathNode = {
        let instance = SnakePlannedPathNode()
        instance.convertCoordinate = { [weak self] (position) in
            return self?.cgPointFromGridPoint(position) ?? CGPoint.zero
        }
        return instance
    }()

	func configureTheme1() {
		let atlas: SKTextureAtlas = SKTextureAtlas(named: "level_theme1")
		do {
            let radius: CGFloat = (AppConstant.tileSize / 2) - 1
            let shapeNode = SKShapeNode(circleOfRadius: radius)
			shapeNode.fillColor = SKColor(named: "Theme1_FoodColor") ?? SKColor.red
            shapeNode.lineWidth = 0
            let node = SKSpriteNode()
            node.addChild(shapeNode)
            node.colorBlendFactor = 1
			self.addChild(node)
			self.node_food = node
		}
		do {
			let texture = atlas.textureNamed("wall")
			let node = SKSpriteNode(texture: texture)
			node.color = SKColor(named: "Theme1_WallColor") ?? SKColor.brown
			node.colorBlendFactor = 1
			self.addChild(node)
			self.node_wall = node
		}
		do {
			self.floorColor = SKColor(named: "Theme1_FloorColor") ?? SKColor.darkGray
		}
	}

	func configureTheme2() {
		let atlas: SKTextureAtlas = SKTextureAtlas(named: "level_theme2")
		do {
			let texture = atlas.textureNamed("nuke")
			let node = SKSpriteNode(texture: texture)
			self.addChild(node)
			self.node_food = node
		}
		do {
			let texture = atlas.textureNamed("wall")
			let node = SKSpriteNode(texture: texture)
			self.addChild(node)
			self.node_wall = node
		}
		do {
			self.floorColor = SKColor(named: "Theme2_FloorColor") ?? SKColor.darkGray
		}
	}

	func configure() {

		switch AppConstant.theme {
		case .theme1:
			configureTheme1()
		case .theme2:
			configureTheme2()
		}

        #if os(macOS)
		snakeBodyNode1.configure(skin: UserDefaults.standard.player1SkinMenuItem)
		snakeBodyNode2.configure(skin: UserDefaults.standard.player2SkinMenuItem)
        snakePlannedPathNode1.configure(skin: UserDefaults.standard.player1SkinMenuItem)
        snakePlannedPathNode2.configure(skin: UserDefaults.standard.player2SkinMenuItem)
        #else
        snakeBodyNode1.configure(skin: PlayerSkinMenuItem.retroGreen)
        snakeBodyNode2.configure(skin: PlayerSkinMenuItem.retroBlue)
        snakePlannedPathNode1.configure(skin: PlayerSkinMenuItem.retroGreen)
        snakePlannedPathNode2.configure(skin: PlayerSkinMenuItem.retroBlue)
        #endif

		self.node_food?.zPosition = 10
		self.node_wall?.zPosition = 20

		self.node_food?.isHidden = true
		self.node_wall?.isHidden = true

		self.snakeBodyNode1.zPosition = 100
		self.snakeBodyNode2.zPosition = 100
		self.addChild(self.snakeBodyNode1)
		self.addChild(self.snakeBodyNode2)

        self.snakePlannedPathNode1.zPosition = 101
        self.snakePlannedPathNode2.zPosition = 102
        self.addChild(self.snakePlannedPathNode1)
        self.addChild(self.snakePlannedPathNode2)

		self.wallNode.zPosition = 100
		wallNode.node_wall = node_wall
		self.addChild(self.wallNode)

		node_food?.repeatPulseEffectForEver(rectOf: 50)
	}

	func rebuildSnakes() {
		//log.debug("player1: \(gameState.player1.snakeBody.fifoContentString)")
		snakeBodyNode1.rebuild(player: gameState.player1)
		snakeBodyNode2.rebuild(player: gameState.player2)
        snakePlannedPathNode1.rebuild(player: gameState.player1, foodPosition: gameState.foodPosition)
        snakePlannedPathNode2.rebuild(player: gameState.player2, foodPosition: gameState.foodPosition)
	}

	lazy var wallNode: SnakeWallNode = {
		let instance = SnakeWallNode()
		instance.convertCoordinate = { [weak self] (position) in
			return self?.cgPointFromGridPoint(position) ?? CGPoint.zero
		}
		return instance
	}()

	func rebuildWall() {
		wallNode.rebuild(snakeLevel: gameState.level)
	}

	func rebuildFloor() {
		node_floor?.removeFromParent()

		let gridSize: CGFloat = AppConstant.tileSize
		let levelSize: UIntVec2 = gameState.level.size
		let shapeSize = CGSize(
			width: CGFloat(levelSize.x) * gridSize,
			height: CGFloat(levelSize.y) * gridSize
		)
		let n = SKShapeNode(rectOf: shapeSize)
		n.zPosition = 0
		n.fillColor = self.floorColor ?? SKColor.brown
		n.lineWidth = 0
		node_floor = n
		self.addChild(n)
	}

	func rebuildFood() {
		if let position: IntVec2 = gameState.foodPosition {
			node_food?.position = cgPointFromGridPoint(position)
			node_food?.isHidden = false
		} else {
			node_food?.isHidden = true
		}
	}

	func redraw() {
		rebuildFloor()
		rebuildWall()
		rebuildFood()
		rebuildSnakes()
	}

	func setScaleToAspectFit(_ size: CGSize) {
		let levelSize: UIntVec2 = gameState.level.size
		let gridSize: CGFloat = AppConstant.tileSize
		let levelWidth = CGFloat(levelSize.x) * gridSize
		let levelHeight = CGFloat(levelSize.y) * gridSize
		let nodeSize: CGSize = size
		let xScale: CGFloat = nodeSize.width / levelWidth
		let yScale: CGFloat = nodeSize.height / levelHeight
		let scale: CGFloat = min(xScale, yScale)
		self.setScale(scale)
		//log.debug("scale: \(scale)  \(nodeSize.width) \(levelWidth)    \(nodeSize.height) \(levelHeight)")
	}

	func cgPointFromGridPoint(_ point: IntVec2) -> CGPoint {
		let gridSize: CGFloat = AppConstant.tileSize
		let midx: CGFloat = CGFloat(gameState.level.size.x) / 2
		let midy: CGFloat = CGFloat(gameState.level.size.y) / 2
		let px: CGFloat = CGFloat(point.x) + 0.5
		let py: CGFloat = CGFloat(point.y) + 0.5
		return CGPoint(x: (px - midx) * gridSize, y: (py - midy) * gridSize)
	}
}
