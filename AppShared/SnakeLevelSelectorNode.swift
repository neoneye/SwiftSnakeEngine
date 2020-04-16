// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

class SnakeLevelSelectorNode: SKSpriteNode {
	let xCellCount: Int
	let yCellCount: Int
	var gameStates: [SnakeGameState] = []
	var gameNodes: [SnakeGameNode] = []
	var selectedIndex: Int?
	var selectionIndicator: SKSpriteNode?

	init(xCellCount: Int, yCellCount: Int, color: SKColor, size: CGSize) {
		guard xCellCount >= 1 && yCellCount >= 1 else {
			fatalError("Expected grid to be bigger than 1x1")
		}
		self.xCellCount = xCellCount
		self.yCellCount = yCellCount
		super.init(texture: nil, color: color, size: size)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	class func create() -> SnakeLevelSelectorNode {
		let size = CGSize(width: 1000, height: 1000)
		let node = SnakeLevelSelectorNode(
			xCellCount: 3,
			yCellCount: 3,
			color: SKColor.clear,
			size: size
		)
		node.selectedIndex = 0
		return node
	}

	func gameStateForSelectedIndex() -> SnakeGameState? {
		guard let selectedIndex: Int = self.selectedIndex else {
			return nil
		}
		guard self.gameStates.indices.contains(selectedIndex) else {
			return nil
		}
		return self.gameStates[selectedIndex]
	}

	func moveSelectionLeft() {
		guard let selectedIndex: Int = self.selectedIndex else {
			self.selectedIndex = 0
			return
		}
		let row: Int = selectedIndex / xCellCount
		let column: Int = (selectedIndex + xCellCount - 1) % xCellCount
		self.selectedIndex = column + row * xCellCount
	}

	func moveSelectionRight() {
		guard let selectedIndex: Int = self.selectedIndex else {
			self.selectedIndex = 0
			return
		}
		let row: Int = selectedIndex / xCellCount
		let column: Int = (selectedIndex + 1) % xCellCount
		self.selectedIndex = column + row * xCellCount
	}

	func moveSelectionUp() {
		guard let selectedIndex: Int = self.selectedIndex else {
			self.selectedIndex = 0
			return
		}
		let cellCount = xCellCount * yCellCount
		self.selectedIndex = (selectedIndex + cellCount - xCellCount) % cellCount
	}

	func moveSelectionDown() {
		guard let selectedIndex: Int = self.selectedIndex else {
			self.selectedIndex = 0
			return
		}
		let cellCount = xCellCount * yCellCount
		self.selectedIndex = (selectedIndex + xCellCount) % cellCount
	}

	func createGameStates() {
        let role1: SnakePlayerRole
        let role2: SnakePlayerRole
        #if os(macOS)
        role1 = UserDefaults.standard.player1RoleMenuItem.role
        role2 = UserDefaults.standard.player2RoleMenuItem.role
        #else

        role1 = SnakePlayerRole.human

        let playerMode: PlayerMode = PlayerModeController().currentPlayerMode
        switch playerMode {
        case .twoPlayer_humanBot:
            let snakeBotType: SnakeBot.Type = SnakeBotFactory.snakeBotTypes.last!
            role2 = SnakePlayerRole.bot(snakeBotType: snakeBotType)
        case .singlePlayer_human:
           role2 = SnakePlayerRole.none
        }
        #endif

		let levelNames: [String] = SnakeLevelManager.shared.levelNames
		let gameStates: [SnakeGameState] = levelNames.map {
			SnakeGameState.create(player1: role1, player2: role2, levelName: $0)
		}
		self.gameStates = gameStates
	}

	func createGameNodes() {
		self.gameNodes = []
		self.removeAllChildren()

		do {
            let color: SKColor
            #if os(macOS)
			color = SKColor(calibratedRed: 0.1, green: 0.8, blue: 0.9, alpha: 1.0)
            #else
            color = SKColor(red: 0.1, green: 0.8, blue: 0.9, alpha: 1.0)
            #endif
			let n = SKSpriteNode(color: color, size: CGSize(width: 100, height: 100))
			n.zPosition = 1
			selectionIndicator = n
			self.addChild(n)
		}

        for (index, _) in self.gameStates.enumerated() {
			let n = SnakeGameNode()
			n.configure()
            n.name = "level \(index)"
            n.isUserInteractionEnabled = false
			gameNodes.append(n)
			n.zPosition = 2
			self.addChild(n)
		}
	}

	func redraw() {
		guard gameNodes.count == gameStates.count else {
			log.error("Expected same number of nodes and states")
			return
		}

		let grid = GridComputer(
			spacing: 90,
			margin: 40,
			xCellCount: self.xCellCount,
			yCellCount: self.yCellCount,
			size: self.size
		)

		for i in gameStates.indices {
			let gameState: SnakeGameState = gameStates[i]
			let gameNode: SnakeGameNode = gameNodes[i]

			gameNode.position = grid.position(index: i)

			gameNode.gameState = gameState
			gameNode.setScaleToAspectFit(grid.gameNodeSize)

			gameNode.redraw()
		}

		if let node = self.selectionIndicator, let index: Int = self.selectedIndex {
			node.isHidden = false
			node.position = grid.position(index: index)
			node.scale(to: grid.selectionNodeSize)
		} else {
			self.selectionIndicator?.isHidden = true
		}
	}
}

fileprivate struct GridComputer {
	let spacing: CGFloat
	let margin: CGFloat
	let xCellCount: Int
	let yCellCount: Int
	let size: CGSize
	let halfSize: CGSize
	let sizeWithoutMargin: CGSize
	let gameNodeSize: CGSize
	let selectionNodeSize: CGSize

	init(spacing: CGFloat, margin: CGFloat, xCellCount: Int, yCellCount: Int, size: CGSize) {
		guard spacing >= 0 && margin >= 0 && xCellCount >= 1 && yCellCount >= 1 && size.width >= 0 && size.height >= 0 else {
			fatalError()
		}
		self.spacing = spacing
		self.margin = margin
		self.xCellCount = xCellCount
		self.yCellCount = yCellCount
		self.size = size
		self.halfSize = CGSize(width: size.width / 2, height: size.height / 2)
		self.sizeWithoutMargin = CGSize(
			width: size.width - ((margin * 2) + (spacing * CGFloat(xCellCount - 1))),
			height: size.height - ((margin * 2) + (spacing * CGFloat(yCellCount - 1)))
		)
		self.gameNodeSize = CGSize(
			width: (sizeWithoutMargin.width) / CGFloat(xCellCount),
			height: (sizeWithoutMargin.height) / CGFloat(yCellCount)
		)
		self.selectionNodeSize = CGSize(
			width: gameNodeSize.width + spacing,
			height: gameNodeSize.height + spacing
		)
	}

	func position(index: Int) -> CGPoint {
		let yy: Int = index / xCellCount
		let xx: Int = index - yy * xCellCount
		let x = CGFloat(xx)
		let y = CGFloat(yCellCount - 1 - yy)
		return CGPoint(
			x: ((gameNodeSize.width + spacing) * x) + (gameNodeSize.width / 2) + margin - halfSize.width,
			y: ((gameNodeSize.height + spacing) * y) + (gameNodeSize.height / 2) + margin - halfSize.height
		)
	}
}
