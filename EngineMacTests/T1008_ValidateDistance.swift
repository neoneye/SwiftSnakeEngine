// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1008_ValidateDistance: XCTestCase {

    func test0_manhattanDistanceIsOne() {
        do {
            let positions: [IntVec2] = []
            XCTAssertTrue(ValidateDistance.manhattanDistanceIsOne(positions))
        }
        do {
            let positions: [IntVec2] = [
                IntVec2(x: 100, y: 200)
            ]
            XCTAssertTrue(ValidateDistance.manhattanDistanceIsOne(positions))
        }
        do {
            let positions: [IntVec2] = [
                IntVec2(x: 12, y: 3),
                IntVec2(x: 13, y: 3),
                IntVec2(x: 13, y: 4)
            ]
            XCTAssertTrue(ValidateDistance.manhattanDistanceIsOne(positions))
        }
        do {
            let positions: [IntVec2] = [
                IntVec2(x: 12, y: 3),
                IntVec2(x: 13, y: 3),
                IntVec2(x: 13, y: 4),
                IntVec2(x: 13, y: 4),
                IntVec2(x: 13, y: 5)
            ]
            XCTAssertFalse(ValidateDistance.manhattanDistanceIsOne(positions))
        }
        do {
            let positions: [IntVec2] = [
                IntVec2(x: 10, y: 1),
                IntVec2(x: 10, y: 3)
            ]
            XCTAssertFalse(ValidateDistance.manhattanDistanceIsOne(positions))
        }
    }
}
