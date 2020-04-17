// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T2002_SnakeBody: XCTestCase {
    func test0_create() {
		let state: SnakeBody = SnakeBody.create(
			position: IntVec2(x: 10, y: 10),
			headDirection: .right,
			length: 2
		)
		XCTAssertEqual(state.head, SnakeHead.test_create(10, 10, .right))
		XCTAssertEqual(state.length, 3)
		do {
			let actual: [IntVec2] = state.positionArray()
			let expected: [IntVec2] = [
				IntVec2(x: 8, y: 10),
				IntVec2(x: 9, y: 10),
				IntVec2(x: 10, y: 10)
			]
			XCTAssertEqual(actual, expected)
		}
		do {
			let actual: [SnakeBodyPartContent] = state.contentArray()
			let expected: [SnakeBodyPartContent] = [
				.empty,
				.empty,
				.empty,
			]
			XCTAssertEqual(actual, expected)
		}
    }

	func test1_moveCW() {
		let state: SnakeBody = SnakeBody.create(
			position: IntVec2(x: 10, y: 10),
			headDirection: .right,
			length: 2
			)
			.stateForTick(movement: .moveCW, act: .doNothing)
		XCTAssertEqual(state.length, 3)
		XCTAssertEqual(state.head, SnakeHead.test_create(10, 9, .down))
		do {
			let actual: [IntVec2] = state.positionArray()
			let expected: [IntVec2] = [
				IntVec2(x: 9, y: 10),
				IntVec2(x: 10, y: 10),
				IntVec2(x: 10, y: 9)
			]
			XCTAssertEqual(actual, expected)
		}
	}

	func test2_moveCCW() {
		let state: SnakeBody = SnakeBody.create(
			position: IntVec2(x: 10, y: 10),
			headDirection: .right,
			length: 2
			)
			.stateForTick(movement: .moveCCW, act: .doNothing)
		XCTAssertEqual(state.length, 3)
		XCTAssertEqual(state.head, SnakeHead.test_create(10, 11, .up))
		do {
			let actual: [IntVec2] = state.positionArray()
			let expected: [IntVec2] = [
				IntVec2(x: 9, y: 10),
				IntVec2(x: 10, y: 10),
				IntVec2(x: 10, y: 11)
			]
			XCTAssertEqual(actual, expected)
		}
	}

	func test3_isEatingItself() {
		var state: SnakeBody = SnakeBody.create(
			position: IntVec2(x: 10, y: 10),
			headDirection: .right,
			length: 5
		)
		XCTAssertFalse(state.isEatingItself)

		state = state.stateForTick(movement: .moveCW, act: .doNothing)
		XCTAssertEqual(state.head, SnakeHead.test_create(10, 9, .down))
		XCTAssertFalse(state.isEatingItself)

		state = state.stateForTick(movement: .moveCW, act: .doNothing)
		XCTAssertEqual(state.head, SnakeHead.test_create(9, 9, .left))
		XCTAssertFalse(state.isEatingItself)

		state = state.stateForTick(movement: .moveCW, act: .doNothing)
		XCTAssertEqual(state.head, SnakeHead.test_create(9, 10, .up))
		XCTAssertTrue(state.isEatingItself)
	}

	func test4_equatable() {
		do {
			let body0: SnakeBody = SnakeBody.create(
				position: IntVec2(x: 10, y: 10),
				headDirection: .right,
				length: 3
			)
			var body1: SnakeBody = SnakeBody.create(
				position: IntVec2(x: 9, y: 10),
				headDirection: .right,
				length: 3
			)
			XCTAssertNotEqual(body0, body1)
			body1 = body1.stateForTick(movement: .moveForward, act: .doNothing)
			XCTAssertEqual(body0, body1)
			body1 = body1.stateForTick(movement: .moveForward, act: .doNothing)
			XCTAssertNotEqual(body0, body1)
		}
		do {
			var body0: SnakeBody = SnakeBody.create(
				position: IntVec2(x: 10, y: 10),
				headDirection: .down,
				length: 3
			)
			var body1: SnakeBody = SnakeBody.create(
				position: IntVec2(x: 10, y: 11),
				headDirection: .down,
				length: 2
			)
			XCTAssertNotEqual(body0, body1)
			body1 = body1.stateForTick(movement: .moveForward, act: .eat)
			body1 = body1.clearedContentOfStomach()
			XCTAssertEqual(body0, body1)
			body0 = body0.stateForTick(movement: .moveForward, act: .doNothing)
			body1 = body1.stateForTick(movement: .moveForward, act: .doNothing)
			XCTAssertEqual(body0, body1)
		}
	}

	func test5_hashable() {
		let body0: SnakeBody = SnakeBody.create(
			position: IntVec2(x: 20, y: 10),
			headDirection: .left,
			length: 5
		)

		var set0 = Set<SnakeBody>()
		set0.insert(body0)
		XCTAssertEqual(set0.count, 1)
		set0.insert(body0)
		XCTAssertEqual(set0.count, 1)

		let body1: SnakeBody = SnakeBody.create(
			position: IntVec2(x: 21, y: 10),
			headDirection: .left,
			length: 4
		)
		set0.insert(body1)
		XCTAssertEqual(set0.count, 2)

		var body2 = body1.stateForTick(movement: .moveForward, act: .eat)
		body2 = body2.clearedContentOfStomach()
		XCTAssertEqual(body0, body2)

		set0.remove(body2)
		XCTAssertEqual(set0.count, 1)
		XCTAssertTrue(set0.contains(body1))
	}
}

extension SnakeHead {
	static func test_create(_ x: Int32, _ y: Int32, _ direction: SnakeHeadDirection) -> SnakeHead {
		return SnakeHead(position: IntVec2(x: x, y: y), direction: direction)
	}
}
