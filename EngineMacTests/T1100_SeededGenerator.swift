// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1100_SeededGenerator: XCTestCase {
    func test0_resetWithSeed0() {
		let seed: UInt64 = 0
		let expected: [UInt8] = [197, 132, 23]
		var generator = SeededGenerator(seed: seed)
		XCTAssertEqual(generator.count, 0)

		let actual0: [UInt8] = generate(3, using: &generator)
		XCTAssertEqual(actual0, expected)
		XCTAssertEqual(generator.count, 3)

		generator.forceReset(seed: seed, count: 0)
		let actual1: [UInt8] = generate(3, using: &generator)
		XCTAssertEqual(actual1, expected)
		XCTAssertEqual(generator.count, 3)

		generator.forceReset(seed: seed, count: 2)
		let actual2: [UInt8] = generate(1, using: &generator)
		XCTAssertEqual(actual2.count, 1)
		XCTAssertEqual(actual2.last, expected.last)
		XCTAssertEqual(generator.count, 3)
	}

	func test1_resetWithSeed1() {
		let seed: UInt64 = 1
		let expected: [UInt8] = [95, 80, 231]
		var generator = SeededGenerator(seed: seed)
		XCTAssertEqual(generator.count, 0)

		let actual0: [UInt8] = generate(3, using: &generator)
		XCTAssertEqual(actual0, expected)
		XCTAssertEqual(generator.count, 3)

		generator.forceReset(seed: seed, count: 0)
		let actual1: [UInt8] = generate(3, using: &generator)
		XCTAssertEqual(actual1, expected)
		XCTAssertEqual(generator.count, 3)

		generator.forceReset(seed: seed, count: 2)
		let actual2: [UInt8] = generate(1, using: &generator)
		XCTAssertEqual(actual2.count, 1)
		XCTAssertEqual(actual2.last, expected.last)
		XCTAssertEqual(generator.count, 3)
    }

	func generate(_ count: UInt, using generator: inout SeededGenerator) -> [UInt8] {
		let values: [UInt8] = (1...count).map { (_) in
			return UInt8.random(in: 0...255, using: &generator)
		}
		return values
	}
}
