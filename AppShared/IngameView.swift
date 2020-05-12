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

            snakePathView()
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

    private func snakePathView() -> some View {
        return SnakePathView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player1SnakeBody
        )
    }
}

struct IngameView_Previews: PreviewProvider {
    static var previews: some View {
        let model = GameViewModel.create()
        return IngameView(model: model)
    }
}
