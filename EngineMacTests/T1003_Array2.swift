// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

fileprivate class Demo_Array2_Int: Array2<Int> {
	init(size: UIntVec2) {
		super.init(size: size, defaultValue: -1)
	}
}


class T1003_Array2: XCTestCase {
    func test100_getset() {
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

    func test200_format() {
        let grid = Array2<Bool>(size: UIntVec2(x: 3, y: 3), defaultValue: false)
        grid.setValue(true, at: IntVec2(x: 0, y: 0))
        grid.setValue(true, at: IntVec2(x: 1, y: 1))
        grid.setValue(true, at: IntVec2(x: 2, y: 2))

        do {
            func prettyValue(value: Bool, position: UIntVec2) -> String {
                value ? "1" : "0"
            }
            let s0: String = grid.format(prettyValue)
            XCTAssertEqual(s0, "1,0,0\n0,1,0\n0,0,1")
            let s1: String = grid.format(columnSeparator: "", rowSeparator: "-", prettyValue)
            XCTAssertEqual(s1, "100-010-001")
        }

        do {
            func prettyPosition(value: Bool, position: UIntVec2) -> String {
                "\(position.x)\(position.y)"
            }
            let s: String = grid.format(prettyPosition)
            XCTAssertEqual(s, "00,10,20\n01,11,21\n02,12,22")
        }
    }
}
