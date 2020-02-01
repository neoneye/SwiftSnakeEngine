// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakeLevelDistanceMapCell {
	case obscured
	case distance(steps: UInt32)
}

/// Compute the shortest distance to the food or other objects of interest.
public class SnakeLevelDistanceMap: Array2<SnakeLevelDistanceMapCell> {
	class func create(level: SnakeLevel, initialPosition: IntVec2?) -> SnakeLevelDistanceMap {
		let level_emptyPositionSet: Set<IntVec2> = level.emptyPositionSet
		return create(levelSize: level.size, emptyPositionSet: level_emptyPositionSet, initialPosition: initialPosition)
	}

	class func create(levelSize: UIntVec2, emptyPositionSet: Set<IntVec2>, initialPosition: IntVec2?) -> SnakeLevelDistanceMap {
		let distanceMap = SnakeLevelDistanceMap(size: levelSize, defaultValue: SnakeLevelDistanceMapCell.obscured)
		guard let initialPosition: IntVec2 = initialPosition else {
			return distanceMap
		}
		var unvisited = emptyPositionSet

		func compute(position: IntVec2, distance: UInt32) {
			guard unvisited.contains(position) else {
				return
			}
			unvisited.remove(position)
			distanceMap.setValue(SnakeLevelDistanceMapCell.distance(steps: distance), at: position)
			let distancePlus1 = distance + 1
			compute(position: position.offsetBy(dx: -1, dy: 0), distance: distancePlus1)
			compute(position: position.offsetBy(dx: 1, dy: 0), distance: distancePlus1)
			compute(position: position.offsetBy(dx: 0, dy: -1), distance: distancePlus1)
			compute(position: position.offsetBy(dx: 0, dy: 1), distance: distancePlus1)
		}

		compute(position: initialPosition, distance: 0)
		return distanceMap
	}
}
