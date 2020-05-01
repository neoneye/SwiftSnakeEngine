// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1009_PrettyPrintArray: XCTestCase {

    func test0_simple() {
        do {
            let values: [Int] = [0, 1, 2, 3, 4]
            let pretty = PrettyPrintArray.simple
            XCTAssertEqual(pretty.format(values), "0,1,2,3,4")
        }
        do {
            let values: [Int] = [0, 1, 2, 3, 4, 5, 6]
            let pretty = PrettyPrintArray.simple
            XCTAssertEqual(pretty.format(values), "0,1,2,...,4,5,6")
        }
    }

    func test1_custom() {
        let values: [Int] = [
            0, 1, 2, 3, 4
        ]
        do {
            let pretty = PrettyPrintArray(prefixLength: 3, suffixLength: 3, separator: ",", ellipsis: "...")
            XCTAssertEqual(pretty.format(values), "0,1,2,3,4")
        }
        do {
            let pretty = PrettyPrintArray(prefixLength: 2, suffixLength: 2, separator: ",", ellipsis: "...")
            XCTAssertEqual(pretty.format(values), "0,1,...,3,4")
        }
    }

}
