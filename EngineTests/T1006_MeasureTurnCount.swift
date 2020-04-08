// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T1006_MeasureTurnCount: XCTestCase {

	func test0() {
		let positions: [IntVec2] = [
			IntVec2(x: 5, y: 10),
			IntVec2(x: 6, y: 10),
			IntVec2(x: 7, y: 10),
			IntVec2(x: 8, y: 10),
			IntVec2(x: 9, y: 10),
			IntVec2(x: 10, y: 10)
		]
		let actual: UInt = MeasureTurnCount.count(positions)
		XCTAssertEqual(actual, 0)
	}

	func test1() {
		let positions: [IntVec2] = [
			IntVec2(x: 8, y: 10),
			IntVec2(x: 9, y: 10),
			IntVec2(x: 10, y: 10),
			IntVec2(x: 10, y: 11),
			IntVec2(x: 10, y: 12),
			IntVec2(x: 10, y: 13)
		]
		let actual: UInt = MeasureTurnCount.count(positions)
		XCTAssertEqual(actual, 1)
	}

	func test2() {
		let positions: [IntVec2] = [
			IntVec2(x: 9, y: 10),
			IntVec2(x: 10, y: 10),
			IntVec2(x: 10, y: 11),
			IntVec2(x: 10, y: 12),
			IntVec2(x: 11, y: 12)
		]
		let actual: UInt = MeasureTurnCount.count(positions)
		XCTAssertEqual(actual, 2)
	}

}
