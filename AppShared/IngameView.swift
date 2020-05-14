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

            player1_snakeBody
            player2_snakeBody

            player1_plannedPath
            player2_plannedPath
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

    private var player1_snakeBody: some View {
        guard model.player1IsInstalled else {
            return AnyView(EmptyView())
        }
        let color: Color
        if model.player1IsAlive {
            color = AppColor.player1_snakeBody.color
        } else {
            color = AppColor.player1_snakeBody_dead.color
        }
        let view = SnakeBodyView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player1SnakeBody,
            fillColor: color
        )
        return AnyView(view)
    }

    private var player2_snakeBody: some View {
        guard model.player2IsInstalled else {
            return AnyView(EmptyView())
        }
        let color: Color
        if model.player1IsAlive {
            color = AppColor.player2_snakeBody.color
        } else {
            color = AppColor.player2_snakeBody_dead.color
        }
        return AnyView(SnakeBodyView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player2SnakeBody,
            fillColor: color
        ))
    }

    private var player1_plannedPath: PlannedPathView {
        let colorHighConfidence: Color = AppColor.player1_plannedPath.color
        let colorLowConfidence: Color = colorHighConfidence.opacity(0.5)
        return PlannedPathView(
            colorHighConfidence: colorHighConfidence,
            colorLowConfidence: colorLowConfidence,
            gridSize: .constant(model.level.size),
            positionArray: $model.player1PlannedPath,
            foodPosition: $model.foodPosition
        )
    }

    private var player2_plannedPath: PlannedPathView {
        let colorHighConfidence: Color = AppColor.player2_plannedPath.color
        let colorLowConfidence: Color = colorHighConfidence.opacity(0.5)
        return PlannedPathView(
            colorHighConfidence: colorHighConfidence,
            colorLowConfidence: colorLowConfidence,
            gridSize: .constant(model.level.size),
            positionArray: $model.player2PlannedPath,
            foodPosition: $model.foodPosition
        )
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
