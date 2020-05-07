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
        } catch SnakeDatasetBundle.LoadError.runtimeError {
            // success
        } catch {
            XCTFail()
        }
    }
}
