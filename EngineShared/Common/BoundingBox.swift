// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public struct BoundingBox {
	public var minx: Int32
	public var maxx: Int32
	public var miny: Int32
	public var maxy: Int32

	public init(position: IntVec2) {
		self.minx = position.x
		self.maxx = position.x
		self.miny = position.y
		self.maxy = position.y
	}

	public mutating func grow(_ position: IntVec2) {
		self.minx = min(self.minx, position.x)
		self.maxx = max(self.maxx, position.x)
		self.miny = min(self.miny, position.y)
		self.maxy = max(self.maxy, position.y)
	}

	public var midx: Int32 {
		(minx + maxx) / 2
	}

	public var midy: Int32 {
		(miny + maxy) / 2
	}

	public func center() -> IntVec2 {
		IntVec2(x: self.midx, y: self.midy)
	}
}
