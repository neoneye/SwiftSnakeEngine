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
}
