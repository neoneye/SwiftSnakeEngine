// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1000_Sigmoid: XCTestCase {

    func test0_sigmoid() {
		do {
			let input: [Float] = [-2, -1, 0, 1, 2]
			let expected: [Float] = [0.12, 0.27, 0.5, 0.73, 0.88]
			for i in input.indices {
				let actual: Float = sigmoid(input[i])
				XCTAssertEqual(actual, expected[i], accuracy: 0.01)
			}
		}
		do {
			let input: [Double] = [-2, -1, 0, 1, 2]
			let expected: [Double] = [0.12, 0.27, 0.5, 0.73, 0.88]
			for i in input.indices {
				let actual: Double = sigmoid(input[i])
				XCTAssertEqual(actual, expected[i], accuracy: 0.01)
			}
		}
    }

	func test1_sigmoidDerived() {
		do {
			let input: [Float] = [0.1, 0.25, 0.5, 0.75, 0.9]
			let expected: [Float] = [0.09, 0.188, 0.25, 0.188, 0.09]
			for i in input.indices {
				let actual: Float = sigmoidDerived(input[i])
				XCTAssertEqual(actual, expected[i], accuracy: 0.01)
			}
		}
		do {
			let input: [Double] = [0.1, 0.25, 0.5, 0.75, 0.9]
			let expected: [Double] = [0.09, 0.188, 0.25, 0.188, 0.09]
			for i in input.indices {
				let actual: Double = sigmoidDerived(input[i])
				XCTAssertEqual(actual, expected[i], accuracy: 0.01)
			}
		}
	}

}
