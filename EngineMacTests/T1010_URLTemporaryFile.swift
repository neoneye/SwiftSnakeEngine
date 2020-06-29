// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T1010_URLTemporaryFile: XCTestCase {
    func test100_noPrefix_noSuffix_noPathExtension() {
        let uuid = UUID()
        let url: URL = URL.temporaryFile(prefixes: [], uuid: uuid, suffixes: [], pathExtension: nil)
        let s: String = url.lastPathComponent
        XCTAssertEqual(s, uuid.uuidString)
    }

    func test200_prefix_and_pathExtension() {
        let uuid = UUID()
        let url: URL = URL.temporaryFile(prefixes: ["snake", "dataset"], uuid: uuid, suffixes: [], pathExtension: "csv")
        let s: String = url.lastPathComponent
        XCTAssertEqual(s, "snake-dataset-\(uuid).csv")
    }

    func test300_suffix() {
        let uuid = UUID()
        let url: URL = URL.temporaryFile(prefixes: [], uuid: uuid, suffixes: ["replay"], pathExtension: nil)
        let s: String = url.lastPathComponent
        XCTAssertEqual(s, "\(uuid)-replay")
    }
}
