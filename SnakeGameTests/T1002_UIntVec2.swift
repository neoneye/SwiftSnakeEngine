// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T1002_UIntVec2: XCTestCase {

	func test0_immutable() {
		let v = UIntVec2(x: 11, y: 22)
		XCTAssertEqual(v.x, 11)
		XCTAssertEqual(v.y, 22)
	}

	func test1_mutate() {
		var v = UIntVec2(x: 1, y: 2)
		v.x = v.x + 1000
		v.y = v.y + 2000
		XCTAssertEqual(v.x, 1001)
		XCTAssertEqual(v.y, 2002)
	}

	func test2_equatable() {
		do {
			let a = UIntVec2(x: 1, y: 2)
			let b = UIntVec2(x: 1, y: 2)
			XCTAssertEqual(a, b)
		}
		do {
			let a = UIntVec2(x: 1, y: 2)
			let b = UIntVec2(x: 300, y: 2)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = UIntVec2(x: 1, y: 2)
			let b = UIntVec2(x: 1, y: 300)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = UIntVec2.zero
			let b = UIntVec2(x: 1, y: 2)
			XCTAssertNotEqual(a, b)
		}
	}

	func test3_offsetBy() {
		do {
			let a = IntVec2(x: 1, y: 2)
			let b = a.offsetBy(dx: 0, dy: 0)
			XCTAssertEqual(a, b)
		}
	}

	func test4_customDebugStringConvertible() {
		do {
			let s = String(reflecting: UIntVec2.zero)
			XCTAssertEqual(s, "(0, 0)")
		}
		do {
			let s = String(reflecting: UIntVec2(x: 123, y: 456))
			XCTAssertEqual(s, "(123, 456)")
		}
	}

	func test5_convertToIntVec2() {
		let a: IntVec2 = UIntVec2(x: 12, y: 34).intVec2
		let b = IntVec2(x: 12, y: 34)
		XCTAssertEqual(a, b)
	}

	func test6_comparable() {
		do {
			let a = UIntVec2(x: 0, y: 0)
			let b = UIntVec2(x: 0, y: 0)
			XCTAssertFalse(a < b)
			XCTAssertFalse(a > b)
			XCTAssertEqual(a, b)
		}
		do {
			let a = UIntVec2(x: 1, y: 2)
			let b = UIntVec2(x: 1, y: 3)
			XCTAssertTrue(a < b)
			XCTAssertFalse(a > b)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = UIntVec2(x: 10, y: 2)
			let b = UIntVec2(x: 50, y: 2)
			XCTAssertTrue(a < b)
			XCTAssertFalse(a > b)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = UIntVec2(x: 1, y: 20)
			let b = UIntVec2(x: 2, y: 20)
			let c = UIntVec2(x: 3, y: 30)
			let d = UIntVec2(x: 4, y: 30)
			let e = UIntVec2(x: 5, y: 40)
			let f = UIntVec2(x: 6, y: 40)
			let actual: [UIntVec2] = [c, f, d, b, e, a].sorted()
			let expected: [UIntVec2] = [a, b, c, d, e, f]
			XCTAssertEqual(actual, expected)
		}
	}

	func test7_hashable() {
		var set0 = Set<UIntVec2>()
		set0.insert(UIntVec2(x: 0, y: 0))
		set0.insert(UIntVec2(x: 10, y: 0))
		set0.insert(UIntVec2(x: 0, y: 10))
		XCTAssertTrue(set0.contains(UIntVec2(x: 0, y: 0)))
		XCTAssertTrue(set0.contains(UIntVec2(x: 10, y: 0)))
		XCTAssertTrue(set0.contains(UIntVec2(x: 0, y: 10)))
		XCTAssertFalse(set0.contains(UIntVec2(x: 666, y: 666)))
		set0.remove(UIntVec2(x: 0, y: 0))
		XCTAssertFalse(set0.contains(UIntVec2(x: 0, y: 0)))
	}
}
