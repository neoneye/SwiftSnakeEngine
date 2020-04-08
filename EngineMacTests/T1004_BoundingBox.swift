// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T1004_BoundingBox: XCTestCase {
    func test0() {
		var bb = BoundingBox(position: IntVec2(x: 1005, y: 3017))
		bb.grow(IntVec2(x: 1000, y: 3000))
		bb.grow(IntVec2(x: 2000, y: 4000))
		XCTAssertEqual(bb.minx, 1000)
		XCTAssertEqual(bb.maxx, 2000)
		XCTAssertEqual(bb.miny, 3000)
		XCTAssertEqual(bb.maxy, 4000)
		XCTAssertEqual(bb.midx, 1500)
		XCTAssertEqual(bb.midy, 3500)
    }
}
