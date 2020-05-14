// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct LevelSelectorGridComputer {
    let margin: EdgeInsets
    let cellSpacing: CGFloat
    let xCellCount: Int
    let yCellCount: Int
    let size: CGSize
    let halfSize: CGSize
    let sizeWithoutMargin: CGSize
    let gameNodeSize: CGSize
    let selectionNodeSize: CGSize

    init(margin: EdgeInsets, cellSpacing: CGFloat, xCellCount: Int, yCellCount: Int, size: CGSize) {
        guard margin.leading >= 0 && margin.top >= 0 && margin.trailing >= 0 && margin.bottom >= 0 else {
            fatalError()
        }
        guard cellSpacing >= 0 && xCellCount >= 1 && yCellCount >= 1 && size.width >= 0 && size.height >= 0 else {
            fatalError()
        }
        self.cellSpacing = cellSpacing
        self.margin = margin
        self.xCellCount = xCellCount
        self.yCellCount = yCellCount
        self.size = size
        self.halfSize = CGSize(width: size.width / 2, height: size.height / 2)
        let marginLeadingTrailing: CGFloat = margin.leading + margin.trailing
        let marginTopBottom: CGFloat = margin.top + margin.bottom
        self.sizeWithoutMargin = CGSize(
            width: size.width - (marginLeadingTrailing + (cellSpacing * CGFloat(xCellCount - 1))),
            height: size.height - (marginTopBottom + (cellSpacing * CGFloat(yCellCount - 1)))
        )
        self.gameNodeSize = CGSize(
            width: (sizeWithoutMargin.width) / CGFloat(xCellCount),
            height: (sizeWithoutMargin.height) / CGFloat(yCellCount)
        )
        self.selectionNodeSize = CGSize(
            width: gameNodeSize.width + cellSpacing,
            height: gameNodeSize.height + cellSpacing
        )
    }

    func position(index: Int) -> CGPoint {
        let yy: Int = index / xCellCount
        let xx: Int = index - yy * xCellCount
        let x = CGFloat(xx)
        let y = CGFloat(yCellCount - 1 - yy)
        return CGPoint(
            x: ((gameNodeSize.width + cellSpacing) * x) + (gameNodeSize.width / 2) + margin.leading - halfSize.width,
            y: ((gameNodeSize.height + cellSpacing) * y) + (gameNodeSize.height / 2) + margin.bottom - halfSize.height
        )
    }
}
