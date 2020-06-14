// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T4000_SnakeDatasetBundle: XCTestCase {
    func test100_success() {
        let resourceName: String = "solo0.snakeDataset"
        let data: Data
        do {
            data = try SnakeDatasetBundle.load(resourceName)
        } catch {
            XCTFail()
            return
        }
        XCTAssertGreaterThan(data.count, 10)
    }

    func test200_error() throws {
        let resourceName: String = "nonExistingFilename.snakeDataset"
        do {
            _ = try SnakeDatasetBundle.load(resourceName)
            XCTFail()
        } catch SnakeDatasetBundleError.custom {
            // success
        } catch {
            XCTFail()
        }
    }

    func test300_urls() {
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
