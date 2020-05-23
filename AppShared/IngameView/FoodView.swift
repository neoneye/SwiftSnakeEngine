// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct FoodView: View {
    @Binding var gridSize: UIntVec2
    @Binding var foodPosition: IntVec2?
    @State var scale: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            self.placeFood(geometry)
        }
    }

    private func placeFood(_ geometry: GeometryProxy) -> some View {
        guard let foodPosition: IntVec2 = self.foodPosition else {
            return AnyView(EmptyView())
        }
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        let circleSize: CGFloat = max(gridComputer.tileMinSize - 4, 1)
        let position = IntVec2(x: foodPosition.x, y: Int32(gridSize.y) - 1 - foodPosition.y)
        let point: CGPoint = gridComputer.position(position)
        let view = Circle()
            .fill(Color.red)
            .frame(width: circleSize, height: circleSize)
            .scaleEffect(scale)
            .position(point)
            .animateForever(autoreverses: true) { self.scale = 0.75 }
        return AnyView(view)
    }
}

extension View {
    fileprivate func animate(using animation: Animation = Animation.easeInOut(duration: 1), _ action: @escaping () -> Void) -> some View {
        return onAppear {
            withAnimation(animation) {
                action()
            }
        }
    }
}

extension View {
    fileprivate func animateForever(using animation: Animation = Animation.easeInOut(duration: 1), autoreverses: Bool = false, _ action: @escaping () -> Void) -> some View {
        let repeated = animation.repeatForever(autoreverses: autoreverses)

        return onAppear {
            withAnimation(repeated) {
                action()
            }
        }
    }
}

struct FoodView_Previews: PreviewProvider {
    static var previews: some View {
        let gridSize = UIntVec2(x: 5, y: 5)
        let foodPosition = IntVec2(x: 2, y: 2)
        return Group {
            FoodView(
                gridSize: .constant(gridSize),
                foodPosition: .constant(foodPosition)
            )
            .previewLayout(.fixed(width: 130, height: 200))

            FoodView(
                gridSize: .constant(gridSize),
                foodPosition: .constant(foodPosition)
            )
            .previewLayout(.fixed(width: 300, height: 200))

            FoodView(
                gridSize: .constant(gridSize),
                foodPosition: .constant(foodPosition)
            )
            .previewLayout(.fixed(width: 500, height: 150))
        }
    }
}
