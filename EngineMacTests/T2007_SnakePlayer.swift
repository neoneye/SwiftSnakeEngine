// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T2007_SnakePlayer: XCTestCase {
    func test100_kill() {
        let player = SnakePlayer.create(id: .player1, role: .human)
        XCTAssertTrue(player.isInstalledAndAlive)
        XCTAssertFalse(player.isInstalledAndDead)
        XCTAssertEqual(player.causesOfDeath.count, 0)

        let playerKilled0: SnakePlayer = player.kill(.collisionWithItself)
        XCTAssertFalse(playerKilled0.isInstalledAndAlive)
        XCTAssertTrue(playerKilled0.isInstalledAndDead)
        XCTAssertEqual(playerKilled0.causesOfDeath.count, 1)

        let playerKilled1: SnakePlayer = playerKilled0.kill(.collisionWithOpponent)
        XCTAssertFalse(playerKilled1.isInstalledAndAlive)
        XCTAssertTrue(playerKilled1.isInstalledAndDead)
        XCTAssertEqual(playerKilled1.causesOfDeath.count, 2)
    }

    func test101_uninstall() {
        let player = SnakePlayer.create(id: .player1, role: .human)
        XCTAssertEqual(player.role, .human)
        XCTAssertTrue(player.isInstalled)
        XCTAssertTrue(player.isInstalledAndAlive)
        XCTAssertTrue(player.isInstalledAndAliveAndHuman)

        let playerUninstalled: SnakePlayer = player.uninstall()
        XCTAssertEqual(playerUninstalled.role, .none)
        XCTAssertFalse(playerUninstalled.isInstalled)
        XCTAssertFalse(playerUninstalled.isInstalledAndAlive)
        XCTAssertFalse(playerUninstalled.isInstalledAndAliveAndHuman)
    }

    func test200_isInstalledAndAlive() {
        do {
            let player = SnakePlayer.create(id: .player1, role: .human)
            XCTAssertTrue(player.isInstalledAndAlive)
            let playerKilled: SnakePlayer = player.kill(.collisionWithItself)
            XCTAssertFalse(playerKilled.isInstalledAndAlive)
            let playerUninstalled: SnakePlayer = player.uninstall()
            XCTAssertFalse(playerUninstalled.isInstalledAndAlive)
        }
        do {
            let player = SnakePlayer.create(id: .player1, role: .none)
            XCTAssertTrue(player.isInstalledAndAlive)
            let playerKilled: SnakePlayer = player.kill(.collisionWithItself)
            XCTAssertFalse(playerKilled.isInstalledAndAlive)
            let playerUninstalled: SnakePlayer = player.uninstall()
            XCTAssertFalse(playerUninstalled.isInstalledAndAlive)
        }
        do {
            let bot: SnakeBot.Type = SnakeBotFactory.smartestBotType()
            let player = SnakePlayer.create(id: .player1, role: .bot(snakeBotType: bot))
            XCTAssertTrue(player.isInstalledAndAlive)
            let playerKilled: SnakePlayer = player.kill(.collisionWithItself)
            XCTAssertFalse(playerKilled.isInstalledAndAlive)
            let playerUninstalled: SnakePlayer = player.uninstall()
            XCTAssertFalse(playerUninstalled.isInstalledAndAlive)
        }
    }

    func test201_isInstalledAndAliveAndHuman() {
        do {
            let player = SnakePlayer.create(id: .player1, role: .human)
            XCTAssertTrue(player.isInstalledAndAliveAndHuman)
            let playerKilled: SnakePlayer = player.kill(.collisionWithWall)
            XCTAssertFalse(playerKilled.isInstalledAndAliveAndHuman)
            let playerUninstalled: SnakePlayer = player.uninstall()
            XCTAssertFalse(playerUninstalled.isInstalledAndAliveAndHuman)
        }
        do {
            let player = SnakePlayer.create(id: .player1, role: .none)
            XCTAssertFalse(player.isInstalledAndAliveAndHuman)
        }
        do {
            let bot: SnakeBot.Type = SnakeBotFactory.smartestBotType()
            let player = SnakePlayer.create(id: .player1, role: .bot(snakeBotType: bot))
            XCTAssertFalse(player.isInstalledAndAliveAndHuman)
        }
    }
}
