// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct IngameGridComputer {
    let viewSize: CGSize
    let gridSize: UIntVec2
    let halfCellSize: CGSize
    let cellSize: CGSize
    let inset: CGPoint
    let tileMinSize: CGFloat

    init(viewSize: CGSize, gridSize: UIntVec2) {
        self.viewSize = viewSize
        self.gridSize = gridSize

        let halfWidth: CGFloat = floor(viewSize.width / CGFloat(gridSize.x * 2))
        let halfHeight: CGFloat = floor(viewSize.height / CGFloat(gridSize.y * 2))
        self.halfCellSize = CGSize(width: halfWidth, height: halfHeight)

        let width: CGFloat = halfWidth * 2
        let height: CGFloat = halfHeight * 2
        let cellSize: CGSize = CGSize(width: width, height: height)
        self.cellSize = cellSize

        let inset: CGPoint = CGPoint(
            x: floor((viewSize.width - width * CGFloat(gridSize.x))/2) + halfWidth,
            y: floor((viewSize.height - height * CGFloat(gridSize.y))/2) + halfHeight
        )
        self.inset = inset

        self.tileMinSize = min(cellSize.width, cellSize.height)
    }

    func position(_ position: IntVec2) -> CGPoint {
        return CGPoint(
            x: CGFloat(position.x) * cellSize.width + inset.x,
            y: CGFloat(position.y) * cellSize.height + inset.y
        )
    }

    func position(_ position: UIntVec2) -> CGPoint {
        return CGPoint(
            x: CGFloat(position.x) * cellSize.width + inset.x,
            y: CGFloat(position.y) * cellSize.height + inset.y
        )
    }
}
