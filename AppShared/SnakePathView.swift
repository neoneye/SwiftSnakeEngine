// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct SnakePathView: View {
    @Binding var gridSize: UIntVec2
    @Binding var snakeBody: SnakeBody

    var body: some View {
        GeometryReader { geometry in
            self.pathWithBevelStroke(geometry)
        }
    }

    private func pathWithBevelStroke(_ geometry: GeometryProxy) -> some View {
        let positions: [IntVec2] = snakeBody.positionArray()
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        let tileMinSize: CGFloat = min(gridComputer.cellSize.width, gridComputer.cellSize.height)
        let lineWidth: CGFloat = tileMinSize - 4
        return Path { path in
            for (index, flippedPosition) in positions.enumerated() {
                let position = IntVec2(x: flippedPosition.x, y: Int32(gridSize.y) - 1 - flippedPosition.y)
                let point: CGPoint = gridComputer.position(position)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(Color.blue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square, lineJoin: .bevel))
    }

    private func pathWithRetro() -> some View {
        Path { path in
            let tileSize: CGFloat = 20
            let halfBorderSize: CGFloat = 8
            let halfCornerOverlap: CGFloat = 5
            let positions: [IntVec2] = snakeBody.positionArray()
            for (index, currentPosition) in positions.enumerated() {
                if index == 0 {
                    continue
                }
                let previousPosition: IntVec2 = positions[index-1]
                let diff: IntVec2 = currentPosition.subtract(previousPosition)
                let dxx: UInt = UInt(diff.x * diff.x)
                let dyy: UInt = UInt(diff.y * diff.y)

                var point0 = CGPoint(
                    x: CGFloat(previousPosition.x) * tileSize,
                    y: CGFloat(previousPosition.y) * tileSize
                )
                var point1 = CGPoint(
                    x: CGFloat(currentPosition.x) * tileSize,
                    y: CGFloat(currentPosition.y) * tileSize
                )

                if dxx > dyy {
                    point0.y -= halfBorderSize
                    point1.y += halfBorderSize
                    if diff.x > 0 {
                        point0.x -= halfCornerOverlap
                        point1.x += halfCornerOverlap
                    } else {
                        point0.x += halfCornerOverlap
                        point1.x -= halfCornerOverlap
                    }
                } else {
                    point0.x -= halfBorderSize
                    point1.x += halfBorderSize
                    if diff.y > 0 {
                        point0.y -= halfCornerOverlap
                        point1.y += halfCornerOverlap
                    } else {
                        point0.y += halfCornerOverlap
                        point1.y -= halfCornerOverlap
                    }
                }

                let x0: CGFloat = min(point0.x, point1.x)
                let y0: CGFloat = min(point0.y, point1.y)
                let x1: CGFloat = max(point0.x, point1.x)
                let y1: CGFloat = max(point0.y, point1.y)
                let rect = CGRect(x: x0, y: y0, width: x1-x0, height: y1-y0)
                path.addRect(rect)
            }
        }
        .fill(Color.red)
    }
}

struct SnakePathView_Previews: PreviewProvider {
    static var previews: some View {
        let positions: [IntVec2] = [
            IntVec2(x:  7, y: 10),
            IntVec2(x:  8, y: 10),
            IntVec2(x:  9, y: 10),
            IntVec2(x: 10, y: 10),
            IntVec2(x: 10, y:  9),
            IntVec2(x: 10, y:  8),
            IntVec2(x: 10, y:  7),
            IntVec2(x: 11, y:  7),
            IntVec2(x: 12, y:  7),
            IntVec2(x: 13, y:  7),
            IntVec2(x: 13, y:  8),
            IntVec2(x: 13, y:  9),
            IntVec2(x: 12, y:  9),
            IntVec2(x: 12, y: 10),
            IntVec2(x: 12, y: 11),
            IntVec2(x: 12, y: 12),
        ]
        guard let snakeBody: SnakeBody = SnakeBody.create(positions: positions) else {
            fatalError("Unable to create snake")
        }
        let gridSize = UIntVec2(x: 14, y: 16)
        
        return Group {
            SnakePathView(
                gridSize: .constant(gridSize),
                snakeBody: .constant(snakeBody)
            )
            .previewLayout(.fixed(width: 130, height: 200))

            SnakePathView(
                gridSize: .constant(gridSize),
                snakeBody: .constant(snakeBody)
            )
            .previewLayout(.fixed(width: 300, height: 200))

            SnakePathView(
                gridSize: .constant(gridSize),
                snakeBody: .constant(snakeBody)
            )
            .previewLayout(.fixed(width: 500, height: 150))
        }
    }
}
