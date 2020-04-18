// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SwiftUI

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

        let playerMode: PlayerMode = PlayerModeController().value
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
			color = SKColor(calibratedRed: 0.7, green: 0.8, blue: 0.9, alpha: 1.0)
            #else
            color = SKColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0)
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
            self.addChild(n)
            n.zPosition = 2
			gameNodes.append(n)
		}
	}

    func redraw(insetTop: CGFloat) {
		guard gameNodes.count == gameStates.count else {
			log.error("Expected same number of nodes and states")
			return
		}

        let clampedInsetTop: CGFloat = min(max(insetTop, 0), 300)
        let margin = EdgeInsets(top: clampedInsetTop + 80, leading: 80, bottom: 80, trailing: 80)
		let grid = GridComputer(
            margin: margin,
			cellSpacing: 80,
			xCellCount: self.xCellCount,
			yCellCount: self.yCellCount,
            size: self.size
		)

		for i in gameStates.indices {
			let gameState: SnakeGameState = gameStates[i]
            let gameNode: SnakeGameNode = gameNodes[i]
            gameNode.gameState = gameState
        }

        let borderSize: CGFloat = 8
        for i in gameStates.indices {
			let gameNode: SnakeGameNode = gameNodes[i]

            // Make the selected level slightly bigger than the non-selected levels.
            var size: CGSize = grid.gameNodeSize
            if i == self.selectedIndex {
                let extra: CGFloat = ceil(grid.cellSpacing * 0.3) * 2 - borderSize
                size.width += extra
                size.height += extra
            }

            gameNode.position = grid.position(index: i)
            gameNode.setScaleToAspectFit(size)

			gameNode.redraw()

            // Draw a thin border around the selected level.
            if i == self.selectedIndex {
                var sizeOfLevel: CGSize = gameNode.sizeOfLevel()
                sizeOfLevel.width *= gameNode.xScale
                sizeOfLevel.height *= gameNode.yScale
                sizeOfLevel.width += borderSize
                sizeOfLevel.height += borderSize
                self.selectionIndicator?.size = sizeOfLevel
                self.selectionIndicator?.position = gameNode.position
            }
		}

		if self.selectedIndex != nil {
			self.selectionIndicator?.isHidden = false
		} else {
			self.selectionIndicator?.isHidden = true
		}
	}
}

fileprivate struct GridComputer {
    let margin: EdgeInsets
	let cellSpacing: CGFloat
	let xCellCount: Int
	let yCellCount: Int
	let size: CGSize
	let halfSize: CGSize
	let sizeWithoutMargin: CGSize
	let gameNodeSize: CGSize
	let selectionNodeSize: CGSize

	init(margin: EdgeInsets, cellSpacing: CGFloat, xCellCount: Int, yCellCount: Int, size: CGSize) {
        guard margin.leading >= 0 && margin.top >= 0 && margin.trailing >= 0 && margin.bottom >= 0 else {
            fatalError()
        }
        guard cellSpacing >= 0 && xCellCount >= 1 && yCellCount >= 1 && size.width >= 0 && size.height >= 0 else {
			fatalError()
		}
		self.cellSpacing = cellSpacing
		self.margin = margin
		self.xCellCount = xCellCount
		self.yCellCount = yCellCount
		self.size = size
		self.halfSize = CGSize(width: size.width / 2, height: size.height / 2)
        let marginLeadingTrailing: CGFloat = margin.leading + margin.trailing
        let marginTopBottom: CGFloat = margin.top + margin.bottom
		self.sizeWithoutMargin = CGSize(
            width: size.width - (marginLeadingTrailing + (cellSpacing * CGFloat(xCellCount - 1))),
            height: size.height - (marginTopBottom + (cellSpacing * CGFloat(yCellCount - 1)))
		)
		self.gameNodeSize = CGSize(
			width: (sizeWithoutMargin.width) / CGFloat(xCellCount),
			height: (sizeWithoutMargin.height) / CGFloat(yCellCount)
		)
		self.selectionNodeSize = CGSize(
			width: gameNodeSize.width + cellSpacing,
			height: gameNodeSize.height + cellSpacing
		)
	}

	func position(index: Int) -> CGPoint {
		let yy: Int = index / xCellCount
		let xx: Int = index - yy * xCellCount
		let x = CGFloat(xx)
		let y = CGFloat(yCellCount - 1 - yy)
		return CGPoint(
            x: ((gameNodeSize.width + cellSpacing) * x) + (gameNodeSize.width / 2) + margin.leading - halfSize.width,
            y: ((gameNodeSize.height + cellSpacing) * y) + (gameNodeSize.height / 2) + margin.bottom - halfSize.height
		)
	}
}
