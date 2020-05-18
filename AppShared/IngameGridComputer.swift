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
    let inset: CGPoint
    let tileMinSize: CGFloat

    init(viewSize: CGSize, gridSize gs: UIntVec2) {
        
        // When trimming the outer cells adjacent to the edge:
        // Then it's left + right sides, so 2 cells removed in the horizontal axis.
        // Then it's top + bottom sides, so 2 cells removed in the vertical axis.
        let cellTrim: Int = Self.trimEdges ? 2 : 0
        let gsx: Int = max(Int(gs.x) - cellTrim, 1)
        let gsy: Int = max(Int(gs.y) - cellTrim, 1)
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

        let inset: CGPoint = CGPoint(
            x: floor((viewSize.width - width * CGFloat(gridSize.x))/2) + halfWidth,
            y: floor((viewSize.height - height * CGFloat(gridSize.y))/2) + halfHeight
        )
        self.inset = inset

        self.tileMinSize = min(cellSize.width, cellSize.height)
    }

    private func computePosition(x: Int, y: Int) -> CGPoint {
        // When trimming the cells near the edges, then we ignore the bottom row, and the left column.
        let cellOffset: Int = Self.trimEdges ? 1 : 0
        return CGPoint(
            x: CGFloat(x - cellOffset) * cellSize.width + inset.x,
            y: CGFloat(y - cellOffset) * cellSize.height + inset.y
        )
    }

    func position(_ position: IntVec2) -> CGPoint {
        return computePosition(x: Int(position.x), y: Int(position.y))
    }

    func position(_ position: UIntVec2) -> CGPoint {
        return computePosition(x: Int(position.x), y: Int(position.y))
    }
}
