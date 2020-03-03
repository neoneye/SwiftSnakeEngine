// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame

class SnakePlannedPathNode: SKEffectNode {
    var pathColor: SKColor = SKColor.darkGray
    var pathLineWidthThick: CGFloat = 20
    var pathLineWidthThin: CGFloat = 1

    typealias CoordinateConverter = (IntVec2) -> CGPoint
    var convertCoordinate: CoordinateConverter?

    func convert(_ position: IntVec2) -> CGPoint {
        return convertCoordinate?(position) ?? CGPoint.zero
    }

    public func configure(skin: PlayerSkinMenuItem) {
        switch skin {
        case .retroGreen, .cuteGreen:
            pathColor = SKColor(calibratedRed: 0.2, green: 0.8, blue: 0.2, alpha: 0.8)
        case .retroBlue, .cuteBlue:
            pathColor = SKColor(calibratedRed: 0.25, green: 0.3, blue: 0.8, alpha: 0.8)
        }
    }

    func rebuild(player: SnakePlayer) {
        guard player.isInstalled else {
            //log.debug("do nothing, since the player is not installed, and thus not shown")
            return
        }

        self.removeAllChildren()
        drawPlannedPathForBot(player)
        drawPendingMovementForHuman(player)
    }

    private func drawPlannedPathForBot(_ player: SnakePlayer) {
        let showPlannedPath: Bool = NSUserDefaultsController.shared.isShowPlannedPathEnabled
        if showPlannedPath && player.isBot && player.isAlive {
            let positionArray: [IntVec2] = player.bot.plannedPath()
            drawPlannedPath(positionArray)
        }
    }

    private func drawPendingMovementForHuman(_ player: SnakePlayer) {
        if player.role == .human {
            // When there are 2 human players and there is no time-constraint,
            // then it's difficult to tell if player1 is waiting for player2 or the other way around.
            // A small hint here is to show the pending move of the fastest player.
            // This way it's possible to see who is ready and who needs to make a move.
            let pendingMovement: SnakeBodyMovement = player.pendingMovement
            switch pendingMovement {
            case .dontMove:
                ()
            case .moveForward, .moveCCW, .moveCW:
                let head0: SnakeHead = player.snakeBody.head
                let head1: SnakeHead = head0.simulateTick(movement: pendingMovement)
                let positionArray: [IntVec2] = [head0.position, head1.position]
                drawPlannedPath(positionArray)
            }
        }
    }

    private func drawPlannedPath(_ positionArray: [IntVec2]) {
        let positionArrayCount: Int = positionArray.count
        guard positionArrayCount >= 2 else {
            //log.debug("Cannot show the planned path, it's too short.")
            return
        }
        let positionArrayCountMinus1: Int = positionArrayCount - 1
        for i in 0..<positionArrayCountMinus1 {
            let position0: IntVec2 = positionArray[i]
            let position1: IntVec2 = positionArray[i + 1]
            let shapeNode = SKShapeNode()
            let pathToDraw = CGMutablePath()
            pathToDraw.move(to: convert(position0))
            pathToDraw.addLine(to: convert(position1))
            shapeNode.path = pathToDraw
            shapeNode.strokeColor = pathColor
            shapeNode.lineWidth = remap(
                CGFloat(i),
                CGFloat(0),
                CGFloat(positionArrayCountMinus1),
                CGFloat(pathLineWidthThick),
                CGFloat(pathLineWidthThin)
            )
            self.addChild(shapeNode)
        }
    }
}
