// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class MeasureTurnCount {
	/// Counts the number of turns that the snake have to make. Lower is better.
	public class func count(_ positions: [IntVec2]) -> UInt {
		guard positions.count >= 3 else {
			return 0
		}
		var turnCount: UInt = 0
		var range = positions.indices
		range.removeLast(2)
		for index in range {
			let a: IntVec2 = positions[index]
			let b: IntVec2 = positions[index + 2]
			let dx: Int = Int(a.x) - Int(b.x)
			let dy: Int = Int(a.y) - Int(b.y)
			let distance: Int = dx * dx + dy * dy
			if distance != 4 {
				turnCount += 1
			}
		}
		return turnCount
	}
}
