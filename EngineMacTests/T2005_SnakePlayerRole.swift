// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T2005_SnakePlayerRole: XCTestCase {

    func test100_create_none() {
        let uuid: UUID = UUID(uuidString: "a036c9e1-ca00-46f5-a960-16451d66390e")!
        guard let role: SnakePlayerRole = SnakePlayerRole.create(uuid: uuid) else {
            XCTFail()
            return
        }
        guard case .none = role else {
            XCTFail()
            return
        }
        XCTAssertEqual(role.id, uuid)
    }

    func test101_create_human() {
        let uuid: UUID = UUID(uuidString: "c7ccdf6d-56ac-491c-857b-be6a80bc6598")!
        guard let role: SnakePlayerRole = SnakePlayerRole.create(uuid: uuid) else {
            XCTFail()
            return
        }
        guard case .human = role else {
            XCTFail()
            return
        }
        XCTAssertEqual(role.id, uuid)
    }

    func test102_create_bot() {
        let uuid: UUID = UUID(uuidString: "ac009b0e-6d2d-4fe5-8dc5-22e3e7c0177d")!
        guard let role: SnakePlayerRole = SnakePlayerRole.create(uuid: uuid) else {
            XCTFail()
            return
        }
        XCTAssertEqual(role.id, uuid)
        guard case .bot(let botType) = role else {
            XCTFail()
            return
        }
        XCTAssertEqual(botType.info.id, uuid)
        XCTAssertTrue(botType is SnakeBot_MoveForward.Type)
    }

    func test200_hashable() {
        do {
            var set = Set<SnakePlayerRole>()
            XCTAssertEqual(set.count, 0)
            set.insert(SnakePlayerRole.human)
            XCTAssertEqual(set.count, 1)
            set.insert(SnakePlayerRole.human)
            XCTAssertEqual(set.count, 1)
            XCTAssertTrue(set.contains(SnakePlayerRole.human))
            set.remove(SnakePlayerRole.human)
            XCTAssertFalse(set.contains(SnakePlayerRole.human))
            XCTAssertEqual(set.count, 0)
        }
        do {
            let bot0: SnakeBot.Type = SnakeBotFactory.emptyBotType()
            let bot1: SnakeBot.Type = SnakeBotFactory.smartestBotType()
            var set = Set<SnakePlayerRole>()
            set.insert(SnakePlayerRole.none)
            set.insert(SnakePlayerRole.human)
            set.insert(SnakePlayerRole.bot(snakeBotType: bot0))
            set.insert(SnakePlayerRole.bot(snakeBotType: bot1))
            XCTAssertEqual(set.count, 4)
            set.remove(SnakePlayerRole.bot(snakeBotType: bot0))
            XCTAssertEqual(set.count, 3)
            set.remove(SnakePlayerRole.bot(snakeBotType: bot1))
            XCTAssertEqual(set.count, 2)
        }
    }
}
