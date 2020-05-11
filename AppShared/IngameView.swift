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
    let level: SnakeLevel

    var body: some View {
        ZStack {
            self.backgroundGradient
                .edgesIgnoringSafeArea(.all)

            LevelView(level: level)

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
        let positions: [IntVec2] = [
            IntVec2(x:  7, y:  8),
            IntVec2(x:  8, y:  8),
            IntVec2(x:  9, y:  8),
            IntVec2(x: 10, y:  8),
            IntVec2(x: 10, y:  7),
            IntVec2(x: 10, y:  6),
            IntVec2(x: 10, y:  5),
            IntVec2(x: 11, y:  5),
            IntVec2(x: 12, y:  5),
            IntVec2(x: 13, y:  5),
        ]
        let snakeBody: SnakeBody = SnakeBody.create(positions: positions)!
        return SnakePathView(
            gridSize: .constant(level.size),
            snakeBody: .constant(snakeBody)
        )
    }
}

struct IngameView_Previews: PreviewProvider {
    static var previews: some View {
        let uuid = UUID(uuidString: "cdeeadf2-31c9-48f4-852f-778b58086dd0")!
        let level: SnakeLevel = SnakeLevelManager.shared.level(id: uuid)!

        return IngameView(level: level)
    }
}
