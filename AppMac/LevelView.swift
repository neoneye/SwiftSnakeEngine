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
            .foregroundColor(Color.red)
    }
}

struct LevelGridView: View {
    let rowCount: UInt
    let columnCount: UInt
    let levelCellArray: [LevelCell]

    var body: some View {
        GeometryReader { geometry in
            self.gridView(geometry)
        }
    }

    private func gridView(_ geometry: GeometryProxy) -> some View {
        let gridComputer = IngameGridComputer(viewSize: geometry.size, columnCount: columnCount, rowCount: rowCount)
        return ZStack(alignment: .topLeading) {
            ForEach(self.levelCellArray) { cell in
                LevelCellView(levelCell: cell)
                    .frame(width: gridComputer.cellSize.width, height: gridComputer.cellSize.height)
                    .position(gridComputer.position(cell.position))
            }
        }
    }
}

struct LevelView: View {
    let level: SnakeLevel

    var body: some View {
        let size: UIntVec2 = level.size
        let levelCellArray: [LevelCell] = LevelCell.create(level: level)

        return LevelGridView(rowCount: UInt(size.y), columnCount: UInt(size.x), levelCellArray: levelCellArray)
    }
}

struct LevelView_Previews: PreviewProvider {
    static var previews: some View {
        let uuid = UUID(uuidString: "cdeeadf2-31c9-48f4-852f-778b58086dd0")!
        let level: SnakeLevel = SnakeLevelManager.shared.level(id: uuid)!

        return Group {
            LevelView(level: level)
                .previewLayout(.fixed(width: 130, height: 200))
            LevelView(level: level)
                .previewLayout(.fixed(width: 300, height: 200))
            LevelView(level: level)
                .previewLayout(.fixed(width: 500, height: 150))
        }
    }
}
