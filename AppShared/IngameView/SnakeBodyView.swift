// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct SnakeBodyView: View {
    @Binding var gridSize: UIntVec2
    @Binding var snakeBody: SnakeBody
    let fillColor: Color

    var body: some View {
        GeometryReader { geometry in
            self.innerView_style0(geometry)
//            self.innerView_style1(geometry)
        }
    }

    private func innerView_style0(_ geometry: GeometryProxy) -> some View {
        let headCornerRadius: CGFloat = 5
        let positions: [IntVec2] = snakeBody.positionArray()
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        let lineWidth: CGFloat = max(gridComputer.tileMinSize * 0.8, 1)
        let bodyView = Path { path in
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
        .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

        var headPoint: CGPoint = .zero
        if let flippedPosition = positions.last {
            let position = IntVec2(x: flippedPosition.x, y: Int32(gridSize.y) - 1 - flippedPosition.y)
            let point: CGPoint = gridComputer.position(position)
            headPoint = point
        }
        let headView = RoundedRectangle(cornerRadius: headCornerRadius, style: .continuous)
            .fill(Color.white)
            .frame(width: gridComputer.tileMinSize, height: gridComputer.tileMinSize)
            .position(headPoint)

        return ZStack {
            bodyView
            headView
        }
        .compositingGroup()
        .colorMultiply(fillColor)
    }

    private func innerView_style1(_ geometry: GeometryProxy) -> some View {
        let positions: [IntVec2] = snakeBody.positionArray()
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        let lineWidth: CGFloat = max(gridComputer.tileMinSize - 4, 1)
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
        .stroke(fillColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square, lineJoin: .bevel))
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
        func f(_ x: Int32, _ y: Int32) -> IntVec2 {
            IntVec2(x: x - 6, y: y - 5)
        }
        let positions: [IntVec2] = [
            f( 7, 10),
            f( 8, 10),
            f( 9, 10),
            f(10, 10),
            f(10,  9),
            f(10,  8),
            f(10,  7),
            f(11,  7),
            f(12,  7),
            f(13,  7),
            f(13,  8),
            f(13,  9),
            f(12,  9),
            f(12, 10),
            f(12, 11),
            f(12, 12),
        ]
        guard let snakeBody: SnakeBody = SnakeBody.create(positions: positions) else {
            fatalError("Unable to create snake")
        }
        let gridSize = UIntVec2(x: 9, y: 9)
        
        return Group {
            SnakeBodyView(
                gridSize: .constant(gridSize),
                snakeBody: .constant(snakeBody),
                fillColor: Color.blue
            )
            .previewLayout(.fixed(width: 130, height: 200))

            SnakeBodyView(
                gridSize: .constant(gridSize),
                snakeBody: .constant(snakeBody),
                fillColor: Color.blue
            )
            .previewLayout(.fixed(width: 300, height: 200))

            SnakeBodyView(
                gridSize: .constant(gridSize),
                snakeBody: .constant(snakeBody),
                fillColor: Color.blue
            )
            .previewLayout(.fixed(width: 500, height: 150))
        }
    }
}
