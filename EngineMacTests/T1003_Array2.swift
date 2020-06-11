// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1003_Array2: XCTestCase {
    func test100_getset() {
		let array = Array2<Int>(size: UIntVec2(x: 2, y: 2), defaultValue: -1)
		array.setValue(0, at: UIntVec2(x: 0, y: 0))
		array.setValue(1, at: UIntVec2(x: 1, y: 0))
		array.setValue(2, at: UIntVec2(x: 0, y: 1))
		array.setValue(3, at: UIntVec2(x: 1, y: 1))
		XCTAssertEqual(array.getValue(UIntVec2(x: 0, y: 0)), 0)
		XCTAssertEqual(array.getValue(UIntVec2(x: 1, y: 0)), 1)
		XCTAssertEqual(array.getValue(UIntVec2(x: 0, y: 1)), 2)
		XCTAssertEqual(array.getValue(UIntVec2(x: 1, y: 1)), 3)
    }

    func test101_subscript() {
        let array = Array2<Int>(size: UIntVec2(x: 2, y: 2), defaultValue: -1)
        array[0, 0] = 0
        array[1, 0] = 1
        array[0, 1] = 2
        array[1, 1] = 3
        XCTAssertEqual(array[0, 0], 0)
        XCTAssertEqual(array[1, 0], 1)
        XCTAssertEqual(array[0, 1], 2)
        XCTAssertEqual(array[1, 1], 3)
    }

    func test200_format() {
        let grid = Array2<Bool>(size: UIntVec2(x: 3, y: 3), defaultValue: false)
        grid[0, 0] = true
        grid[1, 1] = true
        grid[2, 2] = true

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

    func test300_flipX() {
        let grid = Array2<String>(size: UIntVec2(x: 2, y: 3), defaultValue: "x")
        grid[0, 0] = "a"
        grid[0, 1] = "b"
        grid[0, 2] = "c"
        grid[1, 0] = "A"
        grid[1, 1] = "B"
        grid[1, 2] = "C"
        let s0: String = grid.format(columnSeparator: "") { (value, _) in value }
        XCTAssertEqual(s0, "aA\nbB\ncC")
        let gridFlipped = grid.flipX
        let s1: String = gridFlipped.format(columnSeparator: "") { (value, _) in value }
        XCTAssertEqual(s1, "Aa\nBb\nCc")
    }

    func test301_flipY() {
        let grid = Array2<String>(size: UIntVec2(x: 2, y: 3), defaultValue: "x")
        grid[0, 0] = "a"
        grid[0, 1] = "b"
        grid[0, 2] = "c"
        grid[1, 0] = "A"
        grid[1, 1] = "B"
        grid[1, 2] = "C"
        let s0: String = grid.format(columnSeparator: "") { (value, _) in value }
        XCTAssertEqual(s0, "aA\nbB\ncC")
        let gridFlipped = grid.flipY
        let s1: String = gridFlipped.format(columnSeparator: "") { (value, _) in value }
        XCTAssertEqual(s1, "cC\nbB\naA")
    }
}
