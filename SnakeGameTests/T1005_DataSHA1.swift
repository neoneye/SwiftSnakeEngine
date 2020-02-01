// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T1005_DataSHA1: XCTestCase {
    func test0() {
		let data: Data = "hello".data(using: .utf8)!
		let actual: String = data.sha1
		XCTAssertEqual(actual, "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d")
	}
}
