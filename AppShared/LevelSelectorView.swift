// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct LevelSelectorCell: Identifiable {
    let id: UInt
    let position: UIntVec2
    let model: GameViewModel
    let isSelected: Bool

    static func create(gridSize: UIntVec2, models: [GameViewModel], selectedIndex: UInt) -> [LevelSelectorCell] {
        var levelSelectorCellArray = [LevelSelectorCell]()
        for y in 0..<gridSize.y {
            for x in 0..<gridSize.x {
                let index: UInt = UInt(y * gridSize.y + x)
                guard index < models.count else {
                    break
                }
                let model: GameViewModel = models[Int(index)]
                let position = UIntVec2(x: x, y: y)
                let isSelected: Bool = (selectedIndex == index)
                let levelSelectorCell = LevelSelectorCell(id: index, position: position, model: model, isSelected: isSelected)
                levelSelectorCellArray.append(levelSelectorCell)
            }
        }
        return levelSelectorCellArray
    }
}

typealias SelectLevelHandler = (LevelSelectorCell) -> Void

fileprivate struct LevelSelectorCellView: View {
    let selectLevelHandler: SelectLevelHandler
    let levelSelectorCell: LevelSelectorCell

    var body: some View {
        GeometryReader { geometry in
            self.button(geometry)
        }
    }

    private func ingameView(size: CGSize) -> some View {
        let view0 = IngameView(model: levelSelectorCell.model, mode: .levelSelectorPreview)

        let view1: AnyView
        if levelSelectorCell.isSelected {
            view1 = AnyView(view0.border(AppColor.levelSelector_border.color, width: 4))
        } else {
            view1 = AnyView(view0)
        }

        let view2: some View = view1
            .frame(width: size.width, height: size.height)

        return view2
    }

    private func button(_ geometry: GeometryProxy) -> some View {
        var ingameViewSize: CGSize = geometry.size
        ingameViewSize.width -= 4
        ingameViewSize.height -= 4

        return Button(action: {
            log.debug("select level id: \(self.levelSelectorCell.id)")
            self.selectLevelHandler(self.levelSelectorCell)
        }) {
            self.ingameView(size: ingameViewSize)
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
}

fileprivate enum LevelSelectorGridViewStyle {
    case style1
    case style2
}

fileprivate struct LevelSelectorGridView: View {
    let style = LevelSelectorGridViewStyle.style2
    let gridSize: UIntVec2
    let cells: [LevelSelectorCell]
    let selectLevelHandler: SelectLevelHandler

    var body: some View {
        switch style {
        case .style1:
            return AnyView(body_style1)
        case .style2:
            return AnyView(body_style2)
        }
    }

    var body_style1: some View {
        GeometryReader { geometry in
            self.gridView1(geometry)
        }
    }

    var body_style2: some View {
        GeometryReader { geometry in
            self.gridView2(geometry)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }

    private func gridView1(_ geometry: GeometryProxy) -> some View {
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        return ZStack(alignment: .topLeading) {
            ForEach(self.cells) { cell in
                LevelSelectorCellView(selectLevelHandler: self.selectLevelHandler, levelSelectorCell: cell)
                    .frame(width: gridComputer.cellSize.width, height: gridComputer.cellSize.height)
                    .position(gridComputer.position(cell.position))
            }
        }
    }

    private func gridView2(_ geometry: GeometryProxy) -> some View {
        let margin = EdgeInsets(top: 80, leading: 80, bottom: 80, trailing: 80)
        let gridComputer = LevelSelectorGridComputer(
            margin: margin,
            cellSpacing: 80,
            xCellCount: Int(gridSize.x),
            yCellCount: Int(gridSize.y),
            size: geometry.size
        )

        let borderSize: CGFloat = 8

        func cellView(cell: LevelSelectorCell) -> some View {
            // Make the selected level slightly bigger than the non-selected levels.
            var cellSize: CGSize = gridComputer.gameNodeSize
            if cell.isSelected {
                let extra: CGFloat = ceil(gridComputer.cellSpacing * 0.6) * 2 - borderSize
                cellSize.width += extra
                cellSize.height += extra
            }

            let x: UInt = UInt(cell.position.x)
            let y: UInt = UInt(cell.position.y)
            var position: CGPoint = gridComputer.position(x: x, y: y)
            position.x += gridComputer.halfSize.width
            position.y += gridComputer.halfSize.height

            return LevelSelectorCellView(
                selectLevelHandler: self.selectLevelHandler,
                levelSelectorCell: cell
            )
                .frame(width: cellSize.width, height: cellSize.height)
                .position(position)
        }

        return ZStack(alignment: .topLeading) {
            ForEach(self.cells) { cell in
                cellView(cell: cell)
            }
        }
    }
}

struct LevelSelectorView: View {
    @ObservedObject var levelSelectorViewModel: LevelSelectorViewModel
    let selectLevelHandler: SelectLevelHandler

    var body: some View {
        let cells: [LevelSelectorCell] = LevelSelectorCell.create(
            gridSize: levelSelectorViewModel.gridSize,
            models: levelSelectorViewModel.models,
            selectedIndex: levelSelectorViewModel.selectedIndex
        )
        return LevelSelectorGridView(
            gridSize: levelSelectorViewModel.gridSize,
            cells: cells,
            selectLevelHandler: selectLevelHandler
        )
    }
}

struct LevelSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let levelSelectorViewModel = LevelSelectorViewModel()
        levelSelectorViewModel.useMockData()

        return LevelSelectorView(
            levelSelectorViewModel: levelSelectorViewModel,
            selectLevelHandler: {_ in }
        )
    }
}
