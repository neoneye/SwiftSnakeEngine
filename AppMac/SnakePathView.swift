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
    let positions: [IntVec2]

    var body: some View {
        ZStack {
            pathWithBevelStroke()
                .position(x: 150, y: 170)

            pathWithRetro()
                .position(x: 250, y: 230)
        }
        .frame(width: 400, height: 400)
    }

    private func pathWithBevelStroke() -> some View {
        Path { path in
            let tileSize: CGFloat = 20
            for (index, currentPosition) in positions.enumerated() {
                let point = CGPoint(
                    x: CGFloat(currentPosition.x) * tileSize,
                    y: CGFloat(currentPosition.y) * tileSize
                )
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(Color.blue, style: StrokeStyle(lineWidth: 17, lineCap: .butt, lineJoin: .bevel))
    }

    private func pathWithRetro() -> some View {
        Path { path in
            let tileSize: CGFloat = 20
            let halfBorderSize: CGFloat = 8
            let halfCornerOverlap: CGFloat = 5
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
            IntVec2(x: 10, y: 10),
            IntVec2(x: 10, y:  7),
            IntVec2(x: 13, y:  7),
            IntVec2(x: 13, y:  9),
            IntVec2(x: 12, y:  9),
            IntVec2(x: 12, y: 12),
        ]
        return SnakePathView(positions: positions)
    }
}
