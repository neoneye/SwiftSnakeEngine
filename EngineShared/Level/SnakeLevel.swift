// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakeLevelCell {
	case empty
	case wall
}

public class SnakeLevel {
    public let id: UUID
	private let cells: Array2<SnakeLevelCell>
	internal let clusters: Array2<SnakeLevel_ClusterId>
	internal let distanceBetweenClusters: [SnakeLevel_ClusterPair: Int]
	public let size: UIntVec2
	public let initialFoodPosition: UIntVec2
	public let player1_initialPosition: UIntVec2
	public let player1_initialLength: UInt
	public let player1_initialHeadDirection: SnakeHeadDirection
	public let player2_initialPosition: UIntVec2
	public let player2_initialLength: UInt
	public let player2_initialHeadDirection: SnakeHeadDirection
	public let emptyPositionArray: [IntVec2]
	public let emptyPositionSet: Set<IntVec2>

	public class func empty() -> SnakeLevel {
        let uuid = UUID(uuidString: "d5a1eea4-5b9c-4f77-b432-503a169ebfaf")!
        let builder = SnakeLevelBuilder(id: uuid, size: UIntVec2.zero)
		return builder.level()
	}

	/// A `SnakeLevel` can only be create via the `SnakeLevelBuilder` class.
	internal init(
        id: UUID,
		cells: Array2<SnakeLevelCell>,
		clusters: Array2<SnakeLevel_ClusterId>,
		distanceBetweenClusters: [SnakeLevel_ClusterPair: Int],
		size: UIntVec2,
		initialFoodPosition: UIntVec2,
		player1_initialPosition: UIntVec2,
		player1_initialLength: UInt,
		player1_initialHeadDirection: SnakeHeadDirection,
		player2_initialPosition: UIntVec2,
		player2_initialLength: UInt,
		player2_initialHeadDirection: SnakeHeadDirection,
		emptyPositionArray: [IntVec2],
		emptyPositionSet: Set<IntVec2>
	) {
        self.id = id
		self.cells = cells
		self.clusters = clusters
		self.distanceBetweenClusters = distanceBetweenClusters
		self.size = size
		self.initialFoodPosition = initialFoodPosition
		self.player1_initialPosition = player1_initialPosition
		self.player1_initialLength = player1_initialLength
		self.player1_initialHeadDirection = player1_initialHeadDirection
		self.player2_initialPosition = player2_initialPosition
		self.player2_initialLength = player2_initialLength
		self.player2_initialHeadDirection = player2_initialHeadDirection
		self.emptyPositionArray = emptyPositionArray
		self.emptyPositionSet = emptyPositionSet
	}

	public func getValue(_ position: IntVec2) -> SnakeLevelCell? {
		return cells.getValue(position)
	}

	public func getValue(_ position: UIntVec2) -> SnakeLevelCell? {
		return cells.getValue(position)
	}

	public func estimateDistance(position0: IntVec2, position1: IntVec2) -> UInt32 {
		let cluster0: SnakeLevel_ClusterId = clusters.getValue(position0) ?? 0
		let cluster1: SnakeLevel_ClusterId = clusters.getValue(position1) ?? 0
		if cluster0 == cluster1 {
			return position0.manhattanDistance(position1)
		}

		let pair = SnakeLevel_ClusterPair.create(cluster0, cluster1)
		guard let distance: Int = distanceBetweenClusters[pair] else {
			// no route has been computed for this cluster pair
			// this happens when the 2 clusters are neighbouring clusters
			// in this case it's more precist to use using manhattan distance
			return position0.manhattanDistance(position1)
		}
		guard distance >= 0 else {
			// I use -1 whenever the shortest path algo cannot find a path between the clusters.
			// no route exist between the 2 clusters
			return UInt32.max
		}
		return UInt32(distance) * 10
	}
}

extension SnakeLevel: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "SnakeLevel(size: \(size), id: \(id), empty.count: \(emptyPositionArray.count))"
    }
}
