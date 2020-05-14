// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct PlannedPathView: View {
    let colorHighConfidence: Color
    let colorLowConfidence: Color
    @Binding var gridSize: UIntVec2
    let positionArray: [IntVec2]
    let foodPosition: IntVec2

    var body: some View {
        GeometryReader { geometry in
            self.innerView(geometry)
        }
    }

    private func innerView(_ geometry: GeometryProxy) -> some View {
        let positionArrayCount: Int = positionArray.count
        guard positionArrayCount >= 2 else {
            //log.debug("Cannot show the planned path, it's too short.")
            return AnyView(EmptyView())
        }

        let highConfidenceCount: UInt = self.highConfidenceCount(positionArray: positionArray, foodPosition: foodPosition)

        // High confidence. Positions that leads directly to the food.
        var leftRangeEnd = Int(highConfidenceCount + 1)
        if leftRangeEnd >= positionArrayCount {
            leftRangeEnd = positionArrayCount
        }
        let leftSplit: ArraySlice<IntVec2> = positionArray[0 ..< leftRangeEnd]

        // Low confidence. Positions that doesn't lead to the food.
        var rightRangeBegin = Int(highConfidenceCount)
        if rightRangeBegin >= positionArrayCount {
            rightRangeBegin = positionArrayCount
        }
        let rightSplit: ArraySlice<IntVec2> = positionArray[rightRangeBegin ..< positionArray.count]

        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)

        let highConfidenceLineWidth: CGFloat = max(gridComputer.tileMinSize * 0.3, 1)
        let highConfidenceView = self.lineView(
            gridComputer: gridComputer,
            positionArray: Array(leftSplit),
            strokeColor: colorHighConfidence,
            style: StrokeStyle(lineWidth: highConfidenceLineWidth, lineCap: .round, lineJoin: .round)
        )

        let lowConfidenceView = self.lineView(
            gridComputer: gridComputer,
            positionArray: Array(rightSplit),
            strokeColor: colorLowConfidence,
            style: StrokeStyle(lineWidth: 1, lineCap: .square, lineJoin: .miter)
        )

        let view = ZStack {
            lowConfidenceView
            highConfidenceView
        }
        return AnyView(view)
    }

    private func highConfidenceCount(positionArray: [IntVec2], foodPosition: IntVec2?) -> UInt {
        for (index, position) in positionArray.enumerated() {
            if position == foodPosition {
                return UInt(index)
            }
        }
        return 0
    }

    private func lineView(gridComputer: IngameGridComputer, positionArray: [IntVec2], strokeColor: Color, style: StrokeStyle) -> some View {
        guard positionArray.count >= 2 else {
            return AnyView(EmptyView())
        }
        let view = Path { path in
            for (index, flippedPosition) in positionArray.enumerated() {
                let position = IntVec2(x: flippedPosition.x, y: Int32(gridSize.y) - 1 - flippedPosition.y)
                let point: CGPoint = gridComputer.position(position)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(strokeColor, style: style)
        return AnyView(view)
    }

}

struct PlannedPathView_Previews: PreviewProvider {
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
        guard ValidateDistance.distanceIsOne(positions) else {
            fatalError("Positions must be adjacent each other")
        }
        let gridSize = UIntVec2(x: 9, y: 9)

        let colorHighConfidence: Color = Color.green
        let colorLowConfidence: Color = Color.green.opacity(0.3)

        return Group {
            PlannedPathView(
                colorHighConfidence: colorHighConfidence,
                colorLowConfidence: colorLowConfidence,
                gridSize: .constant(gridSize),
                positionArray: positions,
                foodPosition: IntVec2.zero
            )
            .previewLayout(.fixed(width: 130, height: 130))

            PlannedPathView(
                colorHighConfidence: colorHighConfidence,
                colorLowConfidence: colorLowConfidence,
                gridSize: .constant(gridSize),
                positionArray: positions,
                foodPosition: f(13, 8)
            )
            .previewLayout(.fixed(width: 130, height: 130))

            PlannedPathView(
                colorHighConfidence: colorHighConfidence,
                colorLowConfidence: colorLowConfidence,
                gridSize: .constant(gridSize),
                positionArray: positions,
                foodPosition: f(12, 12)
            )
            .previewLayout(.fixed(width: 130, height: 130))
        }
    }
}
