// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T2004_SnakeBodyAdvancedCreate: XCTestCase {
    // MARK: Success scenarios

    func test100_shortestPossibleSnake() throws {
        let positions: [IntVec2] = [
            IntVec2(x: 10, y: 11),
            IntVec2(x: 10, y: 10)
        ]
        let body: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: positions)
        XCTAssertEqual(body.head.position, IntVec2(x: 10, y: 10))
        XCTAssertEqual(body.head.direction, SnakeHeadDirection.down)
        XCTAssertEqual(body.length, 2)
        XCTAssertEqual(body.positionArray(), positions)
    }

    func test101_almostEatingItself() throws {
        let positions: [IntVec2] = [
            IntVec2(x: 10, y: 10),
            IntVec2(x: 11, y: 10),
            IntVec2(x: 11, y: 11),
            IntVec2(x: 10, y: 11),
        ]
        let body: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: positions)
        XCTAssertEqual(body.head.position, IntVec2(x: 10, y: 11))
        XCTAssertEqual(body.head.direction, SnakeHeadDirection.left)
        XCTAssertEqual(body.length, 4)
        XCTAssertEqual(body.positionArray(), positions)
    }

    func test102_zigzagMovements() throws {
        let positions: [IntVec2] = [
            IntVec2(x: 10, y: 10),
            IntVec2(x: 10, y: 11),
            IntVec2(x: 11, y: 11),
            IntVec2(x: 11, y: 12),
            IntVec2(x: 12, y: 12),
            IntVec2(x: 12, y: 13),
        ]
        let body: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: positions)
        XCTAssertEqual(body.head.position, IntVec2(x: 12, y: 13))
        XCTAssertEqual(body.head.direction, SnakeHeadDirection.up)
        XCTAssertEqual(body.length, 6)
        XCTAssertEqual(body.positionArray(), positions)
    }

    // MARK: Error handling

    func test200_error_tooFewParameters() {
        // zero positions
        do {
            _ = try SnakeBodyAdvancedCreate.create(positions: [])
            XCTFail()
        } catch SnakeBodyAdvancedCreate.CreateError.tooFewPositions {
            // success
        } catch {
            XCTFail()
        }

        // one position
        do {
            let positions: [IntVec2] = [IntVec2(x: 10, y: 10)]
            _ = try SnakeBodyAdvancedCreate.create(positions: positions)
            XCTFail()
        } catch SnakeBodyAdvancedCreate.CreateError.tooFewPositions {
            // success
        } catch {
            XCTFail()
        }
    }

    func test201_error_distanceOfOne() {
        // identical
        do {
            let positions: [IntVec2] = [
                IntVec2(x: 10, y: 10),
                IntVec2(x: 10, y: 10)
            ]
            _ = try SnakeBodyAdvancedCreate.create(positions: positions)
            XCTFail()
        } catch SnakeBodyAdvancedCreate.CreateError.distanceOfOne {
            // success
        } catch {
            XCTFail()
        }

        // too far away
        do {
            let positions: [IntVec2] = [
                IntVec2(x: 10, y: 10),
                IntVec2(x: 10, y: 200)
            ]
            _ = try SnakeBodyAdvancedCreate.create(positions: positions)
            XCTFail()
        } catch SnakeBodyAdvancedCreate.CreateError.distanceOfOne {
            // success
        } catch {
            XCTFail()
        }
    }

    func test202_error_eatingItself() {
        do {
            let positions: [IntVec2] = [
                IntVec2(x: 10, y: 10),
                IntVec2(x: 11, y: 10),
                IntVec2(x: 10, y: 10),
            ]
            _ = try SnakeBodyAdvancedCreate.create(positions: positions)
            XCTFail()
        } catch SnakeBodyAdvancedCreate.CreateError.eatingItself {
            // success
        } catch {
            XCTFail()
        }
    }

    func test203_error_eatingItself() {
        do {
            let positions: [IntVec2] = [
                IntVec2(x:  9, y: 10),
                IntVec2(x: 10, y: 10),
                IntVec2(x: 11, y: 10),
                IntVec2(x: 11, y: 11),
                IntVec2(x: 10, y: 11),
                IntVec2(x: 10, y: 10),
                IntVec2(x: 10, y:  9),
            ]
            _ = try SnakeBodyAdvancedCreate.create(positions: positions)
            XCTFail()
        } catch SnakeBodyAdvancedCreate.CreateError.eatingItself {
            // success
        } catch {
            XCTFail()
        }
    }
}
