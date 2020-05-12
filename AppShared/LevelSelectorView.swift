// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

typealias SelectLevelHandler = (GameViewModel) -> Void

fileprivate struct LevelSelectorCell: Identifiable {
    var id: Int
    var position: UIntVec2
    let model: GameViewModel

    static func create(gridSize: UIntVec2, models: [GameViewModel]) -> [LevelSelectorCell] {
        var levelSelectorCellArray = [LevelSelectorCell]()
        for y in 0..<gridSize.y {
            for x in 0..<gridSize.x {
                let index: Int = Int(y * gridSize.y + x)
                guard index < models.count else {
                    break
                }
                let model: GameViewModel = models[index]
                let position = UIntVec2(x: x, y: y)
                let levelSelectorCell = LevelSelectorCell(id: index, position: position, model: model)
                levelSelectorCellArray.append(levelSelectorCell)
            }
        }
        return levelSelectorCellArray
    }
}

fileprivate struct LevelSelectorCellView: View {
    let selectLevelHandler: SelectLevelHandler
    let levelSelectorCell: LevelSelectorCell

    var body: some View {
        GeometryReader { geometry in
            self.button(geometry)
        }
    }

    private func ingameView(size: CGSize) -> some View {
        return IngameView(model: levelSelectorCell.model)
            .frame(width: size.width, height: size.height)
    }

    private func button(_ geometry: GeometryProxy) -> some View {
        var ingameViewSize: CGSize = geometry.size
        ingameViewSize.width -= 4
        ingameViewSize.height -= 4

        return Button(action: {
            log.debug("select level id: \(self.levelSelectorCell.id)")
            self.selectLevelHandler(self.levelSelectorCell.model)
        }) {
            self.ingameView(size: ingameViewSize)
        }
        .buttonStyle(BorderlessButtonStyle())
        .background(Color.yellow)
        .cornerRadius(5)
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
}

fileprivate struct LevelSelectorGridView: View {
    let gridSize: UIntVec2
    let cells: [LevelSelectorCell]
    let selectLevelHandler: SelectLevelHandler

    var body: some View {
        GeometryReader { geometry in
            self.gridView(geometry)
        }
    }

    private func gridView(_ geometry: GeometryProxy) -> some View {
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        return ZStack(alignment: .topLeading) {
            ForEach(self.cells) { cell in
                LevelSelectorCellView(selectLevelHandler: self.selectLevelHandler, levelSelectorCell: cell)
                    .frame(width: gridComputer.cellSize.width, height: gridComputer.cellSize.height)
                    .position(gridComputer.position(cell.position))
            }
        }
    }
}

struct LevelSelectorView: View {
    let gridSize: UIntVec2
    let models: [GameViewModel]
    let selectLevelHandler: SelectLevelHandler

    var body: some View {
        let cells: [LevelSelectorCell] = LevelSelectorCell.create(gridSize: gridSize, models: models)
        return LevelSelectorGridView(gridSize: gridSize, cells: cells, selectLevelHandler: selectLevelHandler)
    }
}

struct LevelSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        var models: [GameViewModel] = []
        models.append(GameViewModel.create())
        models.append(GameViewModel.createBotVsNone())
        models.append(GameViewModel.createBotVsBot())
        models.append(GameViewModel.createHumanVsBot())
        let gridSize = UIntVec2(x: 3, y: 3)
        return LevelSelectorView(gridSize: gridSize, models: models, selectLevelHandler: {_ in })
    }
}
