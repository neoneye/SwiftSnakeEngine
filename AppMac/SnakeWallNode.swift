// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import EngineMac

class SnakeWallNode: SKNode {
	var node_wall: SKSpriteNode?

	typealias CoordinateConverter = (IntVec2) -> CGPoint
	var convertCoordinate: CoordinateConverter?

	func convert(_ position: IntVec2) -> CGPoint {
		return convertCoordinate?(position) ?? CGPoint.zero
	}

	func rebuild(snakeLevel: SnakeLevel) {
		self.removeAllChildren()
		for x in 0..<Int32(snakeLevel.size.x) {
			for y in 0..<Int32(snakeLevel.size.y) {
				let pos = IntVec2(x: x, y: y)
				guard let cell: SnakeLevelCell = snakeLevel.getValue(pos) else {
					continue
				}
				switch cell {
				case .empty:
					()
				case .wall:
					if let n = self.node_wall?.copy() as? SKSpriteNode {
						n.position = convert(pos)
						n.isHidden = false
						self.addChild(n)
					}
				}
			}
		}
	}
}
