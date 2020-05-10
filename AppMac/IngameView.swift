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
    var body: some View {
        ZStack {
            LevelView()

            snakePathView()
        }
    }

    func snakePathView() -> some View {
        let positions: [IntVec2] = [
            IntVec2(x:  7, y: 10),
            IntVec2(x: 10, y: 10),
            IntVec2(x: 10, y:  7),
            IntVec2(x: 13, y:  7),
            IntVec2(x: 13, y:  9),
            IntVec2(x: 12, y:  9),
            IntVec2(x: 12, y: 12),
        ]
        return SnakePathView(rowCount: 20, columnCount: 15, positions: positions)
    }
}

struct IngameView_Previews: PreviewProvider {
    static var previews: some View {
        IngameView()
    }
}
