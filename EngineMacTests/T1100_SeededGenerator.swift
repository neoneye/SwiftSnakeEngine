// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1100_SeededGenerator: XCTestCase {
    func test0_resetWithSeed0() {
		let seed: UInt64 = 0
		let expected: [UInt8] = [45, 166, 59]
		var generator = CountingSeededGenerator(seed: seed)
		XCTAssertEqual(generator.count, 0)

        let actual0: [UInt8] = generator.generate(3)
		XCTAssertEqual(actual0, expected)
		XCTAssertEqual(generator.count, 3)

		generator.seed = seed
        let actual1: [UInt8] = generator.generate(3)
		XCTAssertEqual(actual1, expected)
		XCTAssertEqual(generator.count, 6)

        generator.seed = seed
        var actual2: [UInt8] = []
        actual2 += generator.generate(1)
        actual2 += generator.generate(1)
        actual2 += generator.generate(1)
        XCTAssertEqual(actual2, expected)
        XCTAssertEqual(generator.count, 9)
	}

	func test1_resetWithSeed1() {
		let seed: UInt64 = 1
		let expected: [UInt8] = [42, 175, 32]
		var generator = CountingSeededGenerator(seed: seed)
		XCTAssertEqual(generator.count, 0)

        let actual0: [UInt8] = generator.generate(3)
		XCTAssertEqual(actual0, expected)
		XCTAssertEqual(generator.count, 3)

		generator.seed = seed
        let actual1: [UInt8] = generator.generate(3)
		XCTAssertEqual(actual1, expected)
		XCTAssertEqual(generator.count, 6)

        generator.seed = seed
        var actual2: [UInt8] = []
        actual2 += generator.generate(1)
        actual2 += generator.generate(1)
        actual2 += generator.generate(1)
        XCTAssertEqual(actual2, expected)
        XCTAssertEqual(generator.count, 9)
    }
}

fileprivate struct CountingSeededGenerator: RandomNumberGenerator {
    var generator: SeededGenerator
    var count: Int

    init(seed: UInt64) {
        self.generator = SeededGenerator(seed: seed)
        self.count = 0
    }

    var seed: UInt64 {
        get {
            return self.generator.seed
        }
        set {
            self.generator.seed = newValue
        }
    }

    mutating func next() -> UInt64 {
        count += 1
        return generator.next()
    }
}

extension RandomNumberGenerator {
    fileprivate mutating func generate(_ count: UInt) -> [UInt8] {
        let values: [UInt8] = (1...count).map { (_) in
            return UInt8.random(in: 0...255, using: &self)
        }
        return values
    }
}
