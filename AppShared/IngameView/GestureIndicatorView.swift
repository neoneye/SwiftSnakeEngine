// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct GestureIndicatorView: View {
    let fillColor = Color(white: 0.7).opacity(0.2)
    let strokeColor = Color(white: 0.8)
    @Binding var gridSize: UIntVec2
    @Binding var headPosition: IntVec2

    var body: some View {
        GeometryReader { geometry in
            self.innerView(geometry)
        }
    }

    private func innerView(_ geometry: GeometryProxy) -> some View {
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        let rectSize: CGFloat = gridComputer.tileMinSize - 1
        let position = IntVec2(x: headPosition.x, y: Int32(gridSize.y) - 1 - headPosition.y)
        let point: CGPoint = gridComputer.position(position)
        let cornerRadius: CGFloat = gridComputer.tileMinSize * 0.1

        let roundedRect: RoundedRectangle = RoundedRectangle(cornerRadius: cornerRadius, style: RoundedCornerStyle.circular)

        return ZStack {
            roundedRect
                .fill(fillColor)
            roundedRect
                .stroke(strokeColor, lineWidth: 2.5)
        }
        .frame(width: rectSize, height: rectSize)
        .position(point)
    }
}

struct GestureIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        let gridSize = UIntVec2(x: 3, y: 3)
        let headPosition = IntVec2(x: 1, y: 1)
        return Group {
            GestureIndicatorView(
                gridSize: .constant(gridSize),
                headPosition: .constant(headPosition)
            )
            .previewLayout(.fixed(width: 130, height: 200))

            GestureIndicatorView(
                gridSize: .constant(gridSize),
                headPosition: .constant(headPosition)
            )
            .previewLayout(.fixed(width: 300, height: 200))

            GestureIndicatorView(
                gridSize: .constant(gridSize),
                headPosition: .constant(headPosition)
            )
            .previewLayout(.fixed(width: 500, height: 150))
        }
    }
}
