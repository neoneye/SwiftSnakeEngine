// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1200_ComputeShortestPath: XCTestCase {
	func test0_insertMissingSteps() {
		let path: [IntVec2] = [
			IntVec2(x: 2, y: 2),
			IntVec2(x: 5, y: 2),
			IntVec2(x: 5, y: 5),
		]
		let actual: [IntVec2] = ComputeShortestPath.insertMissingSteps(path)
		let expected: [IntVec2] = [
			IntVec2(x: 2, y: 2),
			IntVec2(x: 3, y: 2),
			IntVec2(x: 4, y: 2),
			IntVec2(x: 5, y: 2),
			IntVec2(x: 5, y: 3),
			IntVec2(x: 5, y: 4),
			IntVec2(x: 5, y: 5),
		]
		XCTAssertEqual(actual, expected)
	}

	func test1_insertMissingSteps() {
		let path: [IntVec2] = [
			IntVec2(x: -2, y: -2),
			IntVec2(x: -5, y: -2),
			IntVec2(x: -5, y: -5),
		]
		let actual: [IntVec2] = ComputeShortestPath.insertMissingSteps(path)
		let expected: [IntVec2] = [
			IntVec2(x: -2, y: -2),
			IntVec2(x: -3, y: -2),
			IntVec2(x: -4, y: -2),
			IntVec2(x: -5, y: -2),
			IntVec2(x: -5, y: -3),
			IntVec2(x: -5, y: -4),
			IntVec2(x: -5, y: -5),
		]
		XCTAssertEqual(actual, expected)
	}

    func test1() {
		let availablePositions: [IntVec2] = [
			IntVec2(x: 5, y: 10),
			IntVec2(x: 6, y: 10),
			IntVec2(x: 7, y: 10),
			IntVec2(x: 8, y: 10),
			IntVec2(x: 9, y: 10),
			IntVec2(x: 10, y: 10)
		]
		let actual: [IntVec2] = ComputeShortestPath.compute(
			availablePositions: availablePositions,
			startPosition: IntVec2(x: 6, y: 10),
			targetPosition: IntVec2(x: 9, y: 10)
		)
		let expected: [IntVec2] = [
			IntVec2(x: 6, y: 10),
			IntVec2(x: 7, y: 10),
			IntVec2(x: 8, y: 10),
			IntVec2(x: 9, y: 10)
		]
		XCTAssertEqual(actual, expected)
    }
}
