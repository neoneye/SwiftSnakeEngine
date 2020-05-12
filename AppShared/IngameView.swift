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
        ZStack {
            self.backgroundGradient
                .edgesIgnoringSafeArea(.all)

            LevelView(model: model)

            player1Snake

            player2Snake
        }
    }

    private var backgroundGradient: LinearGradient {
        let gradient = Gradient(colors: [
            Color(red: 192/255.0, green: 192/255.0, blue: 192/255.0),
            Color(red: 50/255.0, green: 50/255.0, blue: 50/255.0)
        ])
        return LinearGradient(gradient: gradient,
                              startPoint: .top,
                              endPoint: .bottom)
    }

    private var player1Snake: some View {
        return SnakePathView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player1SnakeBody,
            fillColor: Color.blue
        )
    }

    private var player2Snake: some View {
        return SnakePathView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player2SnakeBody,
            fillColor: Color.yellow
        )
    }
}

struct IngameView_Previews: PreviewProvider {
    static var previews: some View {
        let model = GameViewModel.createHumanVsHuman()
        return IngameView(model: model)
    }
}
