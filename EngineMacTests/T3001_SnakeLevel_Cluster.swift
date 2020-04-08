// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T3001_SnakeLevel_Cluster: XCTestCase {

    func test0_clusterPair_create() {
		let low: SnakeLevel_ClusterId = 99
		let high: SnakeLevel_ClusterId = 123

		let pair0 = SnakeLevel_ClusterPair.create(low, high)
		XCTAssertEqual(pair0.low, low)
		XCTAssertEqual(pair0.high, high)

		let pair1 = SnakeLevel_ClusterPair.create(high, low)
		XCTAssertEqual(pair1.low, low)
		XCTAssertEqual(pair1.high, high)
	}

    func test1_clusterPair_equatable() {
		do {
			let pair0 = SnakeLevel_ClusterPair.create(0, 0)
			let pair1 = SnakeLevel_ClusterPair.create(0, 0)
			XCTAssertEqual(pair0, pair1)
		}
		do {
			let pair0 = SnakeLevel_ClusterPair.create(12, 34)
			let pair1 = SnakeLevel_ClusterPair.create(34, 12)
			XCTAssertEqual(pair0, pair1)
		}
		do {
			let pair0 = SnakeLevel_ClusterPair.create(0, 0)
			let pair1 = SnakeLevel_ClusterPair.create(34, 12)
			XCTAssertNotEqual(pair0, pair1)
		}
	}

    func test2_clusterPair_hashable() {
		var dict = [SnakeLevel_ClusterPair: String]()
		do {
			dict[SnakeLevel_ClusterPair.create(0, 0)] = "a"
			dict[SnakeLevel_ClusterPair.create(12, 34)] = "b"
			dict[SnakeLevel_ClusterPair.create(100, 17)] = "OVERWRITE ME"
			dict[SnakeLevel_ClusterPair.create(17, 100)] = "c"
		}
		do {
			let key = SnakeLevel_ClusterPair.create(0, 0)
			let value: String = dict[key] ?? "ERROR"
			XCTAssertEqual(value, "a")
		}
		do {
			let key = SnakeLevel_ClusterPair.create(12, 34)
			let value: String = dict[key] ?? "ERROR"
			XCTAssertEqual(value, "b")
		}
		do {
			let key = SnakeLevel_ClusterPair.create(100, 17)
			let value: String = dict[key] ?? "ERROR"
			XCTAssertEqual(value, "c")
		}
	}

	func test3_clusterPair_comparable() {
		do {
			let a = SnakeLevel_ClusterPair.create(0, 0)
			let b = SnakeLevel_ClusterPair.create(0, 0)
			XCTAssertFalse(a < b)
			XCTAssertFalse(a > b)
			XCTAssertEqual(a, b)
		}
		do {
			let a = SnakeLevel_ClusterPair.create(1, 2)
			let b = SnakeLevel_ClusterPair.create(1, 3)
			XCTAssertTrue(a < b)
			XCTAssertFalse(a > b)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = SnakeLevel_ClusterPair.create(1, 10)
			let b = SnakeLevel_ClusterPair.create(2, 20)
			XCTAssertTrue(a < b)
			XCTAssertFalse(a > b)
			XCTAssertNotEqual(a, b)
		}
		do {
			let a = SnakeLevel_ClusterPair.create(0, 0)
			let b = SnakeLevel_ClusterPair.create(0, 1)
			let c = SnakeLevel_ClusterPair.create(0, 2)
			let d = SnakeLevel_ClusterPair.create(1, 1)
			let e = SnakeLevel_ClusterPair.create(1, 2)
			let f = SnakeLevel_ClusterPair.create(1, 3)
			let actual: [SnakeLevel_ClusterPair] = [c, f, d, b, e, a].sorted()
			let expected: [SnakeLevel_ClusterPair] = [a, b, c, d, e, f]
			XCTAssertEqual(actual, expected)
		}
	}
}
