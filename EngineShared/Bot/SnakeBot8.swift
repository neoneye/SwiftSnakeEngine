// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftCSV

public class SnakeBot8: SnakeBot {
    public static var info = SnakeBotInfo(
        uuid: "ce015558-3705-45e5-9b16-7f79757d2a51",
        name: "Experimental"
    )

    public let plannedMovement: SnakeBodyMovement
    private let iteration: UInt

    private init(iteration: UInt, plannedMovement: SnakeBodyMovement) {
        self.iteration = iteration
        self.plannedMovement = plannedMovement
    }

    required public convenience init() {
        self.init(iteration: 0, plannedMovement: .dontMove)
    }

    public var plannedPath: [IntVec2] {
        []
    }

    public func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> SnakeBot {
        guard player.isInstalledAndAlive else {
            //log.debug("Do nothing. The bot must be installed and alive. It doesn't make sense to run the bot.")
            return SnakeBot8()
        }

        let headPosition: IntVec2 = player.snakeBody.head.position

        // 9x9 grid with obstacles surrounding the head
        let grid = Array2<Bool>(size: UIntVec2(x: 9, y: 9), defaultValue: false)

        // Draw the level walls as obstacles
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                guard let cell: SnakeLevelCell = level.getValue(position) else {
                    grid[x, y] = true
                    continue
                }
                if cell == .wall {
                    grid[x, y] = true
                }
            }
        }

        // Draw players as obstacles
        var playerPositionSet: Set<IntVec2> = player.snakeBody.positionSet()
        if oppositePlayer.isInstalled {
            playerPositionSet.formUnion(oppositePlayer.snakeBody.positionSet())
        }
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                if playerPositionSet.contains(position) {
                    grid[x, y] = true
                }
            }
        }

        let gridString = grid.flipY.format(columnSeparator: " ") { (value, position) in
            value ? "*" : "-"
        }
        log.debug("grid: \(gridString)")

        var values = [Float32]()
        if let position: IntVec2 = foodPosition {
            let diff = headPosition.subtract(position)
//            let diff = position.subtract(headPosition)
            values.append(Float32(diff.x))
            values.append(Float32(diff.y))
        } else {
            values.append(0)
            values.append(0)
        }
        if oppositePlayer.isInstalled {
            let position: IntVec2 = oppositePlayer.snakeBody.head.position
            let diff = headPosition.subtract(position)
            values.append(Float32(diff.x))
            values.append(Float32(diff.y))
        } else {
            values.append(0)
            values.append(0)
        }
        let gridFlipped: Array2<Bool> = grid.flipY
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let cell: Bool = grid[x, y]
//                let cell: Bool = gridFlipped[x, y]
                values.append(cell ? 1 : 0)
            }
        }

        var direction: SnakeHeadDirection = .left
        let index: Int = SnakeBot8Math.shared.compute(values: values)
        switch index {
        case 0:
//            direction = .up
            direction = .down
        case 1:
            direction = .left
        case 2:
            direction = .right
        case 3:
            direction = .up
//            direction = .down
        default:
            log.error("Unable to compute a movement for this step")
            direction = .left
        }
        let pendingMovement: SnakeBodyMovement = player.snakeBody.head.moveToward(direction: direction)

//        let pendingMovement: SnakeBodyMovement = .moveForward

        return SnakeBot8(
            iteration: self.iteration + 1,
            plannedMovement: pendingMovement
        )
    }
}

fileprivate class SnakeBot8Math {
    static let shared = SnakeBot8Math()

    private var setupDone = false
    private var bias: Array2<Float32> = Array2<Float32>(size: UIntVec2.zero, defaultValue: 0)
    private var weight: Array2<Float32> = Array2<Float32>(size: UIntVec2.zero, defaultValue: 0)

    private func setup() {
        if setupDone {
            return
        }
        self.weight = parseCSV(forResource: "SnakeBot8_weight.csv")
        self.bias = parseCSV(forResource: "SnakeBot8_bias.csv")
        setupDone = true
    }

    private func parseCSV(forResource resourceName: String) -> Array2<Float32> {
        guard let url: URL = Bundle(for: SnakeBot8Math.self).url(forResource: resourceName, withExtension: nil) else {
            log.error("Cannot locate \(resourceName) in bundle")
            fatalError()
        }
        //log.debug("url weight: \(url)")

        guard let csv: CSV = try? CSV(url: url, delimiter: ",", encoding: .utf8, loadColumns: false) else {
            log.error("Unable to load CSV. url: \(url)")
            fatalError()
        }

        let rows: [[String]] = csv.enumeratedRows
        guard let columnsInRow0: [String] = rows.first else {
            log.error("Expected 1 or more rows in the csv file, but got none.")
            fatalError()
        }

        let width = UInt32(columnsInRow0.count)
        let height = UInt32(rows.count)
        let size = UIntVec2(x: width, y: height)
        //log.debug("size: \(size)")

        let array: Array2<Float32> = Array2<Float32>(size: size, defaultValue: 0)
        for (y, columns) in rows.enumerated() {
            for (x, value) in columns.enumerated() {
                array[Int32(x), Int32(y)] = Float32(value) ?? 0
            }
        }
//        let arrayString: String = array.format(columnSeparator: " ") { (value, _) in value.string2 }
//        log.debug("array: \(arrayString)")
        return array
    }

    func compute(values: [Float32]) -> Int {
        setup()

        log.debug("values: \(values)")
        log.debug("values.count: \(values.count)")

        log.debug("weight.size: \(weight.size)")
        log.debug("bias.size: \(bias.size)")

        assert(values.count == Int(weight.size.y))
        assert(weight.size.x == 4)
        assert(bias.size.y == 4)
        assert(bias.size.x == 1)

        var result = [Float32](repeating: 0, count: 4)

        // Matrix Multiplication: values X weight
        for x in 0..<4 {
            var sum: Float32 = 0
            for (y, value) in values.enumerated() {
                let w: Float32 = weight[Int32(x), Int32(y)]
                sum += w * value
            }
            result[x] = sum
        }

        // Add bias
        for index in 0..<4 {
            result[index] += bias[Int32(0), Int32(index)]
        }

        let s: String = PrettyPrintArray.simple.format(result)
        log.debug("result: \(s)")

        let result2: [Float32] = result.softmax
        let s2: String = PrettyPrintArray.simple.format(result2)
        log.debug("softmax: \(s2)")

        // argmax
        var foundValue: Float32 = -1
        var foundIndex: Int = -1
        for index in 0..<4 {
            let value: Float32 = result2[index]
            if index == 0 || value > foundValue {
                foundValue = value
                foundIndex = index
            }
        }
        log.debug("argmax: \(foundIndex)")
        return foundIndex
    }
}
