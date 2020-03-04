// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame

class SnakePlannedPathNode: SKEffectNode {
    var pathColorHighConfidence: SKColor = SKColor.gray
    var pathColorLowConfidence: SKColor = SKColor.darkGray
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
            pathColorHighConfidence = SKColor(calibratedRed: 0.1, green: 0.7, blue: 0.1, alpha: 0.9)
        case .retroBlue, .cuteBlue:
            pathColorHighConfidence = SKColor(calibratedRed: 0.25, green: 0.3, blue: 0.8, alpha: 0.9)
        }
        pathColorLowConfidence = pathColorHighConfidence.colorWithOpacity(0.5)
    }

    func rebuild(player: SnakePlayer, foodPosition: IntVec2?) {
        guard player.isInstalled else {
            //log.debug("do nothing, since the player is not installed, and thus not shown")
            return
        }

        self.removeAllChildren()
        drawPlannedPathForBot(player: player, foodPosition: foodPosition)
        drawPendingMovementForHuman(player)
    }

    private func drawPlannedPathForBot(player: SnakePlayer, foodPosition: IntVec2?) {
        let showPlannedPath: Bool = NSUserDefaultsController.shared.isShowPlannedPathEnabled
        if showPlannedPath && player.isBot && player.isAlive {
            let positionArray: [IntVec2] = player.bot.plannedPath()
            let highConfidenceCount: UInt = self.highConfidenceCount(positionArray: positionArray, foodPosition: foodPosition)
            drawPlannedPath(positionArray: positionArray, highConfidenceCount: highConfidenceCount)
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
                drawPlannedPath(positionArray: positionArray, highConfidenceCount: UInt(positionArray.count))
            }
        }
    }

    private func highConfidenceCount(positionArray: [IntVec2], foodPosition: IntVec2?) -> UInt {
        for (index, position) in positionArray.enumerated() {
            if position == foodPosition {
                return UInt(index)
            }
        }
        return 0
    }

    private func drawPlannedPath(positionArray: [IntVec2], highConfidenceCount: UInt) {
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
            if UInt(i) < highConfidenceCount {
                shapeNode.strokeColor = pathColorHighConfidence
            } else {
                shapeNode.strokeColor = pathColorLowConfidence
            }
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


extension SKColor {
    fileprivate func colorWithOpacity(_ opacity: CGFloat) -> SKColor {
        return SKColor(calibratedRed: self.redComponent, green: self.greenComponent, blue: self.blueComponent, alpha: self.alphaComponent * opacity)
    }
}
