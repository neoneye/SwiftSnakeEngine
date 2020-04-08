// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T1001_IntVec2: XCTestCase {

	func test0_immutable() {
		let v = IntVec2(x: 11, y: 22)
		XCTAssertEqual(v.x, 11)
		XCTAssertEqual(v.y, 22)
	}

	func test1_mutate() {
		var v = IntVec2(x: 1, y: 2)
		v.x = v.x + 1000
		v.y = v.y + 2000
		XCTAssertEqual(v.x, 1001)
		XCTAssertEqual(v.y, 2002)
	}

	func test2_equatable() {
		do {
			let a = IntVec2(x: 1, y: 2)
			let b = IntVec2(x: 1, y: 2)
			XCTAssertEqual(a, b)
		}
		do {
			let a = IntVec2(x: 1, y: 2)
			let b = IntVec2(x: 300, y: 2)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = IntVec2(x: 1, y: 2)
			let b = IntVec2(x: 1, y: 300)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = IntVec2.zero
			let b = IntVec2(x: 1, y: 2)
			XCTAssertNotEqual(a, b)
		}
	}

	func test3_hashable() {
		var set0 = Set<IntVec2>()
		set0.insert(IntVec2(x: 0, y: 0))
		set0.insert(IntVec2(x: -10, y: 0))
		set0.insert(IntVec2(x: 10, y: 0))
		set0.insert(IntVec2(x: 0, y: -10))
		set0.insert(IntVec2(x: 0, y: 10))
		XCTAssertTrue(set0.contains(IntVec2(x: 0, y: 0)))
		XCTAssertTrue(set0.contains(IntVec2(x: 10, y: 0)))
		XCTAssertTrue(set0.contains(IntVec2(x: -10, y: 0)))
		XCTAssertTrue(set0.contains(IntVec2(x: 0, y: 10)))
		XCTAssertTrue(set0.contains(IntVec2(x: 0, y: -10)))
		XCTAssertFalse(set0.contains(IntVec2(x: 666, y: 666)))
		set0.remove(IntVec2(x: 0, y: 0))
		XCTAssertFalse(set0.contains(IntVec2(x: 0, y: 0)))
	}

	func test4_offsetBy() {
		do {
			let a = IntVec2(x: -10, y: -1000).offsetBy(dx: 10, dy: 1000)
			let b = IntVec2.zero
			XCTAssertEqual(a, b)
		}
		do {
			let a = IntVec2(x: 1, y: 2)
			let b = a.offsetBy(dx: 0, dy: 0)
			XCTAssertEqual(a, b)
		}
	}

	func test5_customDebugStringConvertible() {
		do {
			let s = String(reflecting: IntVec2.zero)
			XCTAssertEqual(s, "(0, 0)")
		}
		do {
			let s = String(reflecting: IntVec2(x: -123, y: -456))
			XCTAssertEqual(s, "(-123, -456)")
		}
		do {
			let s = String(reflecting: IntVec2(x: 123, y: 456))
			XCTAssertEqual(s, "(123, 456)")
		}
	}

	func test6_convertToUIntVec2() {
		do {
			let point: UIntVec2? = IntVec2(x: 100, y: 100).uintVec2()
			XCTAssertNotNil(point)
		}
		do {
			let point: UIntVec2? = IntVec2.zero.uintVec2()
			XCTAssertNotNil(point)
		}
		do {
			let point: UIntVec2? = IntVec2(x: 0, y: -1).uintVec2()
			XCTAssertNil(point)
		}
		do {
			let point: UIntVec2? = IntVec2(x: -1, y: 0).uintVec2()
			XCTAssertNil(point)
		}
	}

	func test7_convertToCGPoint() {
		do {
			let point: CGPoint = IntVec2.zero.cgPoint
			XCTAssertEqual(point.x, 0.0, accuracy: 0.0001)
			XCTAssertEqual(point.y, 0.0, accuracy: 0.0001)
		}
		do {
			let point: CGPoint = IntVec2(x: 1, y: 2).cgPoint
			XCTAssertEqual(point.x, 1.0, accuracy: 0.0001)
			XCTAssertEqual(point.y, 2.0, accuracy: 0.0001)
		}
		do {
			let point: CGPoint = IntVec2(x: -10, y: -20).cgPoint
			XCTAssertEqual(point.x, -10.0, accuracy: 0.0001)
			XCTAssertEqual(point.y, -20.0, accuracy: 0.0001)
		}
	}

	func test8_manhattanDistance() {
		do {
			let point = IntVec2(x: 0, y: 0)
			let actual: UInt32 = point.manhattanDistance(point)
			XCTAssertEqual(actual, 0)
		}
		do {
			let point0 = IntVec2(x: 10, y: 0)
			let point1 = IntVec2(x: 0, y: 10)
			let actual: UInt32 = point0.manhattanDistance(point1)
			XCTAssertEqual(actual, 20)
		}
		do {
			let point0 = IntVec2(x: 5, y: 0)
			let point1 = IntVec2(x: -5, y: 0)
			let actual: UInt32 = point0.manhattanDistance(point1)
			XCTAssertEqual(actual, 10)
		}
		do {
			let point0 = IntVec2(x: 0, y: 5)
			let point1 = IntVec2(x: 0, y: -5)
			let actual: UInt32 = point0.manhattanDistance(point1)
			XCTAssertEqual(actual, 10)
		}
	}

	func test9_comparable() {
		do {
			let a = IntVec2(x: 0, y: 0)
			let b = IntVec2(x: 0, y: 0)
			XCTAssertFalse(a < b)
			XCTAssertFalse(a > b)
			XCTAssertEqual(a, b)
		}
		do {
			let a = IntVec2(x: 1, y: 2)
			let b = IntVec2(x: 1, y: 3)
			XCTAssertTrue(a < b)
			XCTAssertFalse(a > b)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = IntVec2(x: 10, y: 2)
			let b = IntVec2(x: 50, y: 2)
			XCTAssertTrue(a < b)
			XCTAssertFalse(a > b)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = IntVec2(x: 1, y: -10)
			let b = IntVec2(x: 2, y: -10)
			let c = IntVec2(x: 3, y: 0)
			let d = IntVec2(x: 4, y: 0)
			let e = IntVec2(x: 5, y: 10)
			let f = IntVec2(x: 6, y: 10)
			let actual: [IntVec2] = [c, f, d, b, e, a].sorted()
			let expected: [IntVec2] = [a, b, c, d, e, f]
			XCTAssertEqual(actual, expected)
		}
	}
}
