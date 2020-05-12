// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct LevelCell: Identifiable {
    var id: Int
    var position: UIntVec2

    static func create(level: SnakeLevel) -> [LevelCell] {
        let size: UIntVec2 = level.size
        var levelCellArray = [LevelCell]()
        for y in 0..<size.y {
            for x in 0..<size.x {
                let flippedPosition = UIntVec2(x: x, y: size.y - 1 - y)
                guard let cell: SnakeLevelCell = level.getValue(flippedPosition) else {
                    continue
                }
                if cell == .empty {
                    continue
                }

                let id = Int(y * size.x + x)
                let position = UIntVec2(x: x, y: y)
                let levelCell = LevelCell(id: id, position: position)
                levelCellArray.append(levelCell)
            }
        }
        return levelCellArray
    }
}

struct LevelCellView: View {
    var levelCell: LevelCell

    var body: some View {
        Rectangle()
            .foregroundColor(AppColor.theme1_wall.color)
    }
}

struct LevelGridView: View {
    let gridSize: UIntVec2
    let cells: [LevelCell]

    var body: some View {
        GeometryReader { geometry in
            self.gridView(geometry)
        }
    }

    private func gridView(_ geometry: GeometryProxy) -> some View {
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        return ZStack(alignment: .topLeading) {
            ForEach(self.cells) { cell in
                LevelCellView(levelCell: cell)
                    .frame(width: gridComputer.cellSize.width, height: gridComputer.cellSize.height)
                    .position(gridComputer.position(cell.position))
            }
        }
    }
}

struct LevelView: View {
    @ObservedObject var model: GameViewModel

    var body: some View {
        let level: SnakeLevel = model.level
        let cells: [LevelCell] = LevelCell.create(level: level)
        return LevelGridView(gridSize: level.size, cells: cells)
    }
}

struct LevelView_Previews: PreviewProvider {
    static var previews: some View {
        let model = GameViewModel.create()
        return Group {
            LevelView(model: model)
                .previewLayout(.fixed(width: 130, height: 200))
            LevelView(model: model)
                .previewLayout(.fixed(width: 300, height: 200))
            LevelView(model: model)
                .previewLayout(.fixed(width: 500, height: 150))
        }
    }
}
