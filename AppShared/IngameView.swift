// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct IngameView: View {
    @ObservedObject var model: GameViewModel

    var body: some View {
        let levelSize: UIntVec2 = model.level.size
        let aspectRatio = CGSize(width: CGFloat(levelSize.x), height: CGFloat(levelSize.y))
        return ZStack {
            backgroundSolid
            LevelView(model: model)
            food
            player1Snake
            player2Snake
        }.aspectRatio(aspectRatio, contentMode: .fit)
    }

    private var backgroundSolid: some View {
        Rectangle()
            .foregroundColor(AppColor.theme1_floor.color)
            .edgesIgnoringSafeArea(.all)
    }

    private var food: some View {
        FoodView(
            gridSize: .constant(model.level.size),
            foodPosition: $model.foodPosition
        )
    }

    private var player1Snake: some View {
        guard model.player1IsInstalled else {
            return AnyView(EmptyView())
        }
        let color: Color
        if model.player1IsAlive {
            color = AppColor.player1_snakeBody.color
        } else {
            color = AppColor.player1_snakeBody_dead.color
        }
        let view = SnakePathView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player1SnakeBody,
            fillColor: color
        )
        return AnyView(view)
    }

    private var player2Snake: some View {
        guard model.player2IsInstalled else {
            return AnyView(EmptyView())
        }
        let color: Color
        if model.player1IsAlive {
            color = AppColor.player2_snakeBody.color
        } else {
            color = AppColor.player2_snakeBody_dead.color
        }
        return AnyView(SnakePathView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player2SnakeBody,
            fillColor: color
        ))
    }
}

struct IngameView_Previews: PreviewProvider {
    static var previews: some View {
        let model = GameViewModel.createHumanVsHuman()
        return Group {
            IngameView(model: model)
                .previewLayout(.fixed(width: 130, height: 200))
            IngameView(model: model)
                .previewLayout(.fixed(width: 300, height: 200))
            IngameView(model: model)
                .previewLayout(.fixed(width: 400, height: 150))
        }
    }
}
