// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

fileprivate class Demo_Array2_Int: Array2<Int> {
	init(size: UIntVec2) {
		super.init(size: size, defaultValue: -1)
	}
}


class T1003_Array2: XCTestCase {
    func test0() {
		let array = Demo_Array2_Int(size: UIntVec2(x: 2, y: 2))
		array.setValue(0, at: UIntVec2(x: 0, y: 0))
		array.setValue(1, at: UIntVec2(x: 1, y: 0))
		array.setValue(2, at: UIntVec2(x: 0, y: 1))
		array.setValue(3, at: UIntVec2(x: 1, y: 1))

		XCTAssertEqual(array.getValue(UIntVec2(x: 0, y: 0)), 0)
		XCTAssertEqual(array.getValue(UIntVec2(x: 1, y: 0)), 1)
		XCTAssertEqual(array.getValue(UIntVec2(x: 0, y: 1)), 2)
		XCTAssertEqual(array.getValue(UIntVec2(x: 1, y: 1)), 3)
    }
}
