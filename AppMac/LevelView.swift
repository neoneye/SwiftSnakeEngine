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
            ZStack {
                self.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                self.gridView(geometry)
            }
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

    private func compute(cell: LevelCell, size: CGSize, inset: CGPoint) -> CGPoint {
        return CGPoint(
            x: CGFloat(cell.position.x) * size.width + inset.x,
            y: CGFloat(cell.position.y) * size.height + inset.y
        )
    }

    private func gridView(_ geometry: GeometryProxy) -> some View {
        let halfWidth: CGFloat = floor(geometry.size.width / CGFloat(columnCount * 2))
        let halfHeight: CGFloat = floor(geometry.size.height / CGFloat(rowCount * 2))
        let width: CGFloat = halfWidth * 2
        let height: CGFloat = halfHeight * 2
        let size: CGSize = CGSize(width: width, height: height)
        let inset: CGPoint = CGPoint(
            x: floor((geometry.size.width - width * CGFloat(columnCount))/2) + halfWidth,
            y: floor((geometry.size.height - height * CGFloat(rowCount))/2) + halfHeight
        )
        return ZStack(alignment: .topLeading) {
            ForEach(self.levelCellArray) { cell in
                LevelCellView(levelCell: cell)
                    .frame(width: width, height: height)
                    .position(self.compute(cell: cell, size: size, inset: inset))
            }
        }
    }
}

struct LevelView: View {
    var body: some View {
        let uuid = UUID(uuidString: "cdeeadf2-31c9-48f4-852f-778b58086dd0")!
        let level: SnakeLevel = SnakeLevelManager.shared.level(id: uuid)!
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

        return LevelGridView(rowCount: UInt(size.y), columnCount: UInt(size.x), levelCellArray: levelCellArray)
    }
}

struct LevelView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            LevelView()
                .previewLayout(.fixed(width: 130, height: 200))
            LevelView()
                .previewLayout(.fixed(width: 300, height: 200))
            LevelView()
                .previewLayout(.fixed(width: 500, height: 150))
        }
    }
}
