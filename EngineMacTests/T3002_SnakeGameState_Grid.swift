// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T3002_SnakeGameState_Grid: XCTestCase {

    func test() {
        let b = SnakeLevelBuilder(id: UUID(), size: UIntVec2(x: 5, y: 5))
        b.installWallsAroundTheLevel()
        let level: SnakeLevel = b.level()
        XCTAssertEqual(level.emptyPositionArray.count, 9)

        var state = SnakeGameState.empty()
        state = state.stateWithNewLevel(level)
        state = state.stateWithNewPlayer1(state.player1.uninstall())
        state = state.stateWithNewPlayer2(state.player2.uninstall())
        do {
            // Without any players
            let grid: Array2<GridCell> = state.grid(radius: 2, center: IntVec2(x: 2, y: 2))
            XCTAssertEqual("WWWWW,W   W,W   W,W   W,WWWWW", format(grid))
        }

        do {
            var player = SnakePlayer.create(id: .player1, role: .human)
            let body: SnakeBody = SnakeBody.create(positions: [IntVec2(x: 1, y: 1), IntVec2(x: 2, y: 1), IntVec2(x: 3, y: 1)])!
            player = player.playerWithNewSnakeBody(body)
            state = state.stateWithNewPlayer1(player)
        }
        do {
            var player = SnakePlayer.create(id: .player2, role: .human)
            let body: SnakeBody = SnakeBody.create(positions: [IntVec2(x: 1, y: 3), IntVec2(x: 2, y: 3), IntVec2(x: 3, y: 3)])!
            player = player.playerWithNewSnakeBody(body)
            player = player.kill(.other)
            state = state.stateWithNewPlayer2(player)
        }

        do {
            // With both player1 and player2
            let grid0: Array2<GridCell> = state.grid(radius: 2, center: IntVec2(x: 2, y: 2))
            XCTAssertEqual("WWWWW,W111W,W   W,W222W,WWWWW", format(grid0))

            let grid1: Array2<GridCell> = state.grid(radius: 2, center: IntVec2(x: 2, y: 1))
            XCTAssertEqual("WWWWW,WWWWW,W111W,W   W,W222W", format(grid1))

            let grid2: Array2<GridCell> = state.grid(radius: 2, center: IntVec2(x: 2, y: 0))
            XCTAssertEqual("WWWWW,WWWWW,WWWWW,W111W,W   W", format(grid2))
        }
    }

    func format(_ grid: Array2<GridCell>) -> String {
        return grid.format(columnSeparator: "", rowSeparator: ",") { (gridCell, _) -> String in
            gridCell.pretty
        }
    }
}

extension GridCell {
    fileprivate var pretty: String {
        switch self {
        case .empty:
            return " "
        case .wall:
            return "W"
        case .player1:
            return "1"
        case .player2:
            return "2"
        }
    }
}
