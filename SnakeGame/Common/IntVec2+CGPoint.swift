// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import CoreGraphics

extension IntVec2 {
	/// Returns a CGPoint initialized with the `x` and `y` coordinates.
	public var cgPoint: CGPoint {
		return CGPoint(x: Int(self.x), y: Int(self.y))
	}
}
