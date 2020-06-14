// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T4000_SnakeDatasetBundle: XCTestCase {
    func test100_urlForResource_success() {
        let resourceName: String = "solo0.snakeDataset"
        let data: Data
        do {
            let url: URL = try SnakeDatasetBundle.url(forResource: resourceName)
            data = try Data(contentsOf: url)
        } catch {
            XCTFail()
            return
        }
        XCTAssertGreaterThan(data.count, 10)
    }

    func test101_urlForResource_error() throws {
        let resourceName: String = "nonExistingFilename.snakeDataset"
        do {
            _ = try SnakeDatasetBundle.url(forResource: resourceName)
            XCTFail()
        } catch SnakeDatasetBundleError.custom {
            // success
        } catch {
            XCTFail()
        }
    }

    func test200_urls() {
        let urls: [URL]
        do {
            urls = try SnakeDatasetBundle.urls()
        } catch {
            XCTFail()
            return
        }
        XCTAssertGreaterThan(urls.count, 5)
    }
}
