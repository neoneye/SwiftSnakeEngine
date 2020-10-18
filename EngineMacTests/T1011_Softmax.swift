// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1011_Softmax: XCTestCase {

    func test0_softmax() {
        let input: [Float] = [0.6689292,0.2620013,1.0744656,-0.8190495]
        let expected: [Float] = [0.29484367,0.19627512,0.44229704,0.06658415]
        let actual: [Float] = input.softmax
        for i in input.indices {
            XCTAssertEqual(actual[i], expected[i], accuracy: 0.01)
        }
    }

}
