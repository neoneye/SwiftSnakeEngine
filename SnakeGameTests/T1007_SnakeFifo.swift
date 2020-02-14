// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T1007_SnakeFifo: XCTestCase {
	typealias SnakeFifoString = SnakeFifo<String>

	func test0_equatable() {
		let fifo0 = SnakeFifoString()
		fifo0.appendAndGrow("a")
		fifo0.appendAndGrow("b")
		fifo0.appendAndGrow("c")
		XCTAssertEqual(fifo0, fifo0)
		let fifo1 = SnakeFifoString()
		fifo1.appendAndGrow("a")
		fifo1.appendAndGrow("b")
		XCTAssertNotEqual(fifo0, fifo1)
		fifo1.appendAndGrow("c")
		XCTAssertEqual(fifo0, fifo1)
		fifo1.appendAndGrow("d")
		XCTAssertNotEqual(fifo0, fifo1)
	}

	func test1_hashable() {
		let fifo0 = SnakeFifoString(array: ["a", "b", "c"])
		let fifo1a = SnakeFifoString(array: ["b", "c", "d"])
		let fifo1b = SnakeFifoString(array: ["b", "c", "d"])
		var set0 = Set<SnakeFifoString>()
		XCTAssertFalse(set0.contains(fifo0))
		XCTAssertFalse(set0.contains(fifo1a))
		XCTAssertFalse(set0.contains(fifo1b))
		set0.insert(fifo0)
		set0.insert(fifo1a)
		XCTAssertEqual(set0.count, 2)
		XCTAssertTrue(set0.contains(fifo0))
		XCTAssertTrue(set0.contains(fifo1a))
		XCTAssertTrue(set0.contains(fifo1b))
		fifo0.append("x")
		XCTAssertFalse(set0.contains(fifo0))
		set0.insert(fifo0)
		XCTAssertEqual(set0.count, 3)
		XCTAssertTrue(set0.contains(fifo0))
	}
}
