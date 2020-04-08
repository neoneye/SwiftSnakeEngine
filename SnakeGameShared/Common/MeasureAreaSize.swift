// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class MeasureAreaSize {
	public class func compute(positionArray: [IntVec2], startPosition: IntVec2) -> UInt {
		return compute(
			positionSet: Set<IntVec2>(positionArray),
			startPosition: startPosition
		)
	}

	public class func compute(positionSet: Set<IntVec2>, startPosition: IntVec2) -> UInt {
		var unvisited: Set<IntVec2> = positionSet
		var fillCount: UInt = 0

		func compute(position: IntVec2) {
			guard unvisited.contains(position) else {
				return
			}
			unvisited.remove(position)
			fillCount += 1
			compute(position: position.offsetBy(dx: -1, dy: 0))
			compute(position: position.offsetBy(dx: 1, dy: 0))
			compute(position: position.offsetBy(dx: 0, dy: -1))
			compute(position: position.offsetBy(dx: 0, dy: 1))
		}

		compute(position: startPosition)
		return UInt(fillCount)
	}
}
