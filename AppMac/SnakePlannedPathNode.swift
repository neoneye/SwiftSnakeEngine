// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import SnakeGame

class SnakePlannedPathNode: SKEffectNode {
    var colorHighConfidence: SKColor = SKColor.gray
    var colorLowConfidence: SKColor = SKColor.darkGray

    typealias CoordinateConverter = (IntVec2) -> CGPoint
    var convertCoordinate: CoordinateConverter?

    func convert(_ position: IntVec2) -> CGPoint {
        return convertCoordinate?(position) ?? CGPoint.zero
    }

    public func configure(skin: PlayerSkinMenuItem) {
        switch skin {
        case .retroGreen, .cuteGreen:
            colorHighConfidence = SKColor(calibratedRed: 0.1, green: 0.7, blue: 0.1, alpha: 0.9)
        case .retroBlue, .cuteBlue:
            colorHighConfidence = SKColor(calibratedRed: 0.25, green: 0.3, blue: 0.8, alpha: 0.9)
        }
        colorLowConfidence = colorHighConfidence.colorWithOpacity(0.5)
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
            if let position0: IntVec2 = positionArray.first {
                log.debug("position0: \(position0)")
            }
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

        var leftRangeEnd = Int(highConfidenceCount + 1)
        if leftRangeEnd >= positionArrayCount {
            leftRangeEnd = positionArrayCount
        }
        let leftSplit: ArraySlice<IntVec2> = positionArray[0 ..< leftRangeEnd]

        var rightRangeBegin = Int(highConfidenceCount)
        if rightRangeBegin >= positionArrayCount {
            rightRangeBegin = positionArrayCount
        }
        let rightSplit: ArraySlice<IntVec2> = positionArray[rightRangeBegin ..< positionArray.count]

        if leftSplit.count >= 2 {
//            if let position0: IntVec2 = leftSplit.first {
//                log.debug("position0: \(position0)")
//            }
            let shapeNode: SKShapeNode = shapeNodeWithPath(positionArray: Array(leftSplit))
            shapeNode.strokeColor = colorHighConfidence
            shapeNode.lineWidth = 30
            shapeNode.lineCap = .round
            shapeNode.lineJoin = .round
            self.addChild(shapeNode)
        }
        if rightSplit.count >= 2 {
            let shapeNode: SKShapeNode = shapeNodeWithPath(positionArray: Array(rightSplit))
            shapeNode.strokeColor = colorLowConfidence
            shapeNode.lineWidth = 2
            self.addChild(shapeNode)
        }
    }

    private func shapeNodeWithPath(positionArray: [IntVec2]) -> SKShapeNode {
        assert(positionArray.count >= 2)
        let positionArrayCount: Int = positionArray.count
        let positionArrayCountMinus1: Int = positionArrayCount - 1
        let pathToDraw = CGMutablePath()
        for i in 0..<positionArrayCountMinus1 {
            let position0: IntVec2 = positionArray[i]
            let position1: IntVec2 = positionArray[i + 1]
            if i == 0 {
                pathToDraw.move(to: convert(position0))
            }
            pathToDraw.addLine(to: convert(position1))
        }
        return SKShapeNode(path: pathToDraw)
    }
}


extension SKColor {
    fileprivate func colorWithOpacity(_ opacity: CGFloat) -> SKColor {
        return SKColor(calibratedRed: self.redComponent, green: self.greenComponent, blue: self.blueComponent, alpha: self.alphaComponent * opacity)
    }
}
