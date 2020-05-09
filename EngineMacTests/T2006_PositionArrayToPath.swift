// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T2006_PositionArrayToPath: XCTestCase {
    func test100_noLinesToCombine() {
        let input: [IntVec2] = [
            IntVec2(x: 10, y: 10),
            IntVec2(x: 10, y: 11),
            IntVec2(x: 11, y: 11),
            IntVec2(x: 11, y: 12),
            IntVec2(x: 12, y: 12),
            IntVec2(x: 12, y: 13),
        ]
        let expected: [IntVec2] = input
        let actual: [IntVec2] = input.toPath()
        XCTAssertEqual(actual, expected)
    }

    func test101_combineLines() {
        let input: [IntVec2] = [
            IntVec2(x:  6, y: 10),
            IntVec2(x:  7, y: 10),
            IntVec2(x:  8, y: 10),
            IntVec2(x:  9, y: 10),
            IntVec2(x: 10, y: 10),
        ]
        let expected: [IntVec2] = [
            IntVec2(x:  6, y: 10),
            IntVec2(x: 10, y: 10),
        ]
        let actual: [IntVec2] = input.toPath()
        XCTAssertEqual(actual, expected)
    }

    func test102_combineLines() {
        let input: [IntVec2] = [
            IntVec2(x:  7, y: 10),
            IntVec2(x:  8, y: 10),
            IntVec2(x:  9, y: 10),
            IntVec2(x: 10, y: 10),
            IntVec2(x: 10, y:  9),
            IntVec2(x: 10, y:  8),
            IntVec2(x: 10, y:  7),
            IntVec2(x:  9, y:  7),
            IntVec2(x:  8, y:  7),
            IntVec2(x:  7, y:  7),
        ]
        let expected: [IntVec2] = [
            IntVec2(x:  7, y: 10),
            IntVec2(x: 10, y: 10),
            IntVec2(x: 10, y:  7),
            IntVec2(x:  7, y:  7),
        ]
        let actual: [IntVec2] = input.toPath()
        XCTAssertEqual(actual, expected)
    }
}
