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
    // In order to reduce wasted screen estate on small displays.
    // This gets rid of the wall cells that surrounds the level.
    static let trimEdges = true

    let viewSize: CGSize
    let gridSize: UIntVec2
    let halfCellSize: CGSize
    let cellSize: CGSize
    let translate: CGPoint
    let tileMinSize: CGFloat

    init(viewSize originalViewSize: CGSize, gridSize originalGridView: UIntVec2) {
        // At first I wanted to reduce wasted screen estate as much as possible.
        // I removed the outer cells adjacent to the level edge, so that
        // the level extends entirely to the screen edge.
        // However this gave the impression that the content had been cropped by accident.
        // So I have added a small amount of padding around level.
        let viewTrim: CGFloat = 2
        let viewTrimBothSides: CGFloat = viewTrim * 2
        let vsx: CGFloat = max(originalViewSize.width - viewTrimBothSides, 1)
        let vsy: CGFloat = max(originalViewSize.height - viewTrimBothSides, 1)
        let viewSize = CGSize(width: vsx, height: vsy)

        // When trimming the outer cells adjacent to the edge:
        // Then it's left + right sides, so 2 cells removed in the horizontal axis.
        // Then it's top + bottom sides, so 2 cells removed in the vertical axis.
        let cellTrim: Int = Self.trimEdges ? 2 : 0
        let gsx: Int = max(Int(originalGridView.x) - cellTrim, 1)
        let gsy: Int = max(Int(originalGridView.y) - cellTrim, 1)
        let gridSize: UIntVec2 = UIntVec2(x: UInt32(gsx), y: UInt32(gsy))
        self.viewSize = viewSize
        self.gridSize = gridSize

        let halfWidth: CGFloat = floor(viewSize.width / CGFloat(gridSize.x * 2))
        let halfHeight: CGFloat = floor(viewSize.height / CGFloat(gridSize.y * 2))
        self.halfCellSize = CGSize(width: halfWidth, height: halfHeight)

        let width: CGFloat = halfWidth * 2
        let height: CGFloat = halfHeight * 2
        let cellSize: CGSize = CGSize(width: width, height: height)
        self.cellSize = cellSize

        var translate = CGPoint.zero
        do {
            // Remaining space outside the grid size, but still inside the view size
            translate.x += floor((viewSize.width - width * CGFloat(gridSize.x))/2)
            translate.y += floor((viewSize.height - height * CGFloat(gridSize.y))/2)
        }
        do {
            // Center in the midx midy of the cell.
            translate.x += halfWidth
            translate.y += halfHeight
        }
        do {
            // Small amount of padding around the view.
            translate.x += viewTrim
            translate.y += viewTrim
        }
        if Self.trimEdges {
            // When trimming the cells near the edges, then we ignore the bottom row, and the left column.
            translate.x -= width
            translate.y -= height
        }

        self.translate = translate

        self.tileMinSize = min(cellSize.width, cellSize.height)
    }

    private func computePosition(x: Int, y: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(x) * cellSize.width + translate.x,
            y: CGFloat(y) * cellSize.height + translate.y
        )
    }

    func position(_ position: IntVec2) -> CGPoint {
        return computePosition(x: Int(position.x), y: Int(position.y))
    }

    func position(_ position: UIntVec2) -> CGPoint {
        return computePosition(x: Int(position.x), y: Int(position.y))
    }
}
