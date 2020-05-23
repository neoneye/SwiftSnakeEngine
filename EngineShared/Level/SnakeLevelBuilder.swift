// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeLevelBuilder {
    public let id: UUID
	private let cells: Array2<SnakeLevelCell>
	internal let clusters: Array2<SnakeLevel_ClusterId>
	public let size: UIntVec2
	public var initialFoodPosition: UIntVec2 = UIntVec2.zero
    public var player1_body: SnakeBody = SnakeBody.empty()
    public var player2_body: SnakeBody = SnakeBody.empty()
	public var precomputed_distanceBetweenClusters: [SnakeLevel_ClusterPair: Int]?

	public init(id: UUID, size: UIntVec2) {
        self.id = id
		self.cells = Array2<SnakeLevelCell>(size: size, defaultValue: SnakeLevelCell.empty)
		self.clusters = Array2<SnakeLevel_ClusterId>(size: size, defaultValue: 0)
		self.size = size
	}

	public func level() -> SnakeLevel {
		let emptyPositionArray: [IntVec2] = computeEmptyPositionArray()
		let emptyPositionSet: Set<IntVec2> = Set<IntVec2>(emptyPositionArray)

		let distanceBetweenClusters: [SnakeLevel_ClusterPair: Int]
		if let precomputed = precomputed_distanceBetweenClusters {
			distanceBetweenClusters = precomputed
		} else {
			let ignoreTheseAdjacentClusterPairs: Set<SnakeLevel_ClusterPair> = SnakeLevelBuilder.adjacentClusterPairs(emptyPositionSet: emptyPositionSet, clusters: self.clusters)
			distanceBetweenClusters = SnakeLevelBuilder.computeDistancesBetweenClusters(emptyPositionArray: emptyPositionArray, clusters: self.clusters, ignoreTheseAdjacentClusterPairs: ignoreTheseAdjacentClusterPairs)
		}

		return SnakeLevel(
            id: self.id,
			cells: self.cells,
			clusters: self.clusters,
			distanceBetweenClusters: distanceBetweenClusters,
			size: self.size,
			initialFoodPosition: self.initialFoodPosition,
            player1_body: self.player1_body,
            player2_body: self.player2_body,
			emptyPositionArray: emptyPositionArray,
			emptyPositionSet: emptyPositionSet
		)
	}

	internal func computeEmptyPositionArray() -> [IntVec2] {
		var positions = [IntVec2]()
		for y in 0..<cells.size.y {
			for x in 0..<cells.size.x {
				let position = UIntVec2(x: x, y: y)
				guard let cell: SnakeLevelCell = cells.getValue(position) else {
					continue
				}
				if cell == .empty {
					positions.append(position.intVec2)
				}
			}
		}
		return positions
	}

	public func installWall(at position: UIntVec2) {
		cells.setValue(.wall, at: position)
	}

    /// Draw an outer wall around the level.
    public func installWallsAroundTheLevel() {
        guard cells.size.x >= 1 && cells.size.y >= 1 else {
            return
        }
        for x in 0..<cells.size.x {
            cells.setValue(.wall, at: UIntVec2(x: x, y: 0))
            cells.setValue(.wall, at: UIntVec2(x: x, y: cells.size.y - 1))
        }
        for y in 0..<cells.size.y {
            cells.setValue(.wall, at: UIntVec2(x: 0, y: y))
            cells.setValue(.wall, at: UIntVec2(x: cells.size.x - 1, y: y))
        }
    }

	public func assignCluster(_ clusterId: SnakeLevel_ClusterId, at position: UIntVec2) {
		clusters.setValue(clusterId, at: position)
	}

	private class func computeDistancesBetweenClusters(
		emptyPositionArray: [IntVec2],
		clusters: Array2<SnakeLevel_ClusterId>,
		ignoreTheseAdjacentClusterPairs: Set<SnakeLevel_ClusterPair>
	) -> [SnakeLevel_ClusterPair: Int] {
		let t0 = CFAbsoluteTimeGetCurrent()

		// compute bounding box of each cluster
		var boundingBoxes = [SnakeLevel_ClusterId: BoundingBox]()
		for position in emptyPositionArray {
			guard let cluster: SnakeLevel_ClusterId = clusters.getValue(position) else {
				continue
			}
			var box: BoundingBox = boundingBoxes[cluster] ?? BoundingBox(position: position)
			box.grow(position)
			boundingBoxes[cluster] = box
		}
		guard boundingBoxes.count >= 2 else {
            //log.debug("Level without any clusters. Ignoring. A level must have at least 2 clusters in order to compute distances between clusters")
			return [:]
		}
		let clusterArray: [SnakeLevel_ClusterId] = boundingBoxes.keys.sorted()
        log.debug("Identified \(clusterArray.count) unique clusters: \(clusterArray)")
		//log.debug("boundingBoxes: \(boundingBoxes)")

		// Compute center of each cluster
		let boundingBoxCenters: [SnakeLevel_ClusterId: IntVec2] = boundingBoxes.mapValues { $0.center() }
		//log.debug("boundingBoxCenters: \(boundingBoxCenters)")

		// Find actual cells that are near the center
		var nearestCellPosition = [SnakeLevel_ClusterId: IntVec2]()
		var nearestCellDistance = [SnakeLevel_ClusterId: UInt32]()
		for position in emptyPositionArray {
			guard let cluster: SnakeLevel_ClusterId = clusters.getValue(position) else {
				continue
			}
			guard let center: IntVec2 = boundingBoxCenters[cluster] else {
                log.error("Expected to have boundingBoxCenters for all clusters, but \(cluster) is missing.")
				continue
			}
			let bestDistance: UInt32 = nearestCellDistance[cluster] ?? UInt32.max
			let distance: UInt32 = position.manhattanDistance(center)
			if distance < bestDistance {
				nearestCellDistance[cluster] = distance
				nearestCellPosition[cluster] = position
			}
		}
		//log.debug("nearestCellDistance: \(nearestCellDistance)")
		//log.debug("nearestCellPosition: \(nearestCellPosition)")

		//log.debug("ignoreTheseAdjacentClusterPairs: \(ignoreTheseAdjacentClusterPairs)")

		var distanceBetweenClusters = [SnakeLevel_ClusterPair: Int]()
		for cluster0: SnakeLevel_ClusterId in clusterArray {
			for cluster1: SnakeLevel_ClusterId in clusterArray {
				if cluster0 == cluster1 {
					// The distance between the cluster with itself, is always zero. So we don't compute it.
					continue
				}
				let pair = SnakeLevel_ClusterPair.create(cluster0, cluster1)
				guard !ignoreTheseAdjacentClusterPairs.contains(pair) else {
					// Skip clusters that are neighbours.
					// It's more precise to use manhattan distance.
					continue
				}
				if distanceBetweenClusters.keys.contains(pair) {
					// We have already computed it, no need to recompute it.
					continue
				}
				guard let center0: IntVec2 = nearestCellPosition[cluster0] else {
                    log.error("Expected to have a nearest position for all clusters, but \(cluster0) is missing.")
					distanceBetweenClusters[pair] = -1
					continue
				}
				guard let center1: IntVec2 = nearestCellPosition[cluster1] else {
                    log.error("Expected to have a nearest position for all clusters, but \(cluster1) is missing.")
					distanceBetweenClusters[pair] = -1
					continue
				}

				// compute distance between cluster centers
				// IDEA: reuse the same graph over and over for faster computation
				let plannedPath: [IntVec2] = ComputeShortestPath.compute(
					availablePositions: emptyPositionArray,
					startPosition: center0,
					targetPosition: center1
				)

				guard !plannedPath.isEmpty else {
					// The plannedPath is empty when there are no route between the clusters.
					// Use "-1" to indicate that there is no route.
					log.debug("\(pair) has no planned path")
					distanceBetweenClusters[pair] = -1
					continue
				}

				let distance: Int = plannedPath.count
				distanceBetweenClusters[pair] = distance

				//log.debug("\(pair) = \(distance)")
			}
		}

		let t1 = CFAbsoluteTimeGetCurrent()
		let elapsed: Double = t1 - t0

		log.debug("distanceBetweenClusters.count \(distanceBetweenClusters.count)  elapsed \(elapsed)")
		//log.debug("distanceBetweenClusters: \(distanceBetweenClusters)")

		return distanceBetweenClusters
	}

	public func computeAdjacentClusterPairs() -> Set<SnakeLevel_ClusterPair> {
		let emptyPositionArray: [IntVec2] = self.computeEmptyPositionArray()
		let emptyPositionSet: Set<IntVec2> = Set<IntVec2>(emptyPositionArray)
		let pairs: Set<SnakeLevel_ClusterPair> = SnakeLevelBuilder.adjacentClusterPairs(emptyPositionSet: emptyPositionSet, clusters: self.clusters)
		return pairs
	}

	public class func adjacentClusterPairs(emptyPositionSet: Set<IntVec2>, clusters: Array2<SnakeLevel_ClusterId>) -> Set<SnakeLevel_ClusterPair> {
		var adjacentClusterPairs = Set<SnakeLevel_ClusterPair>()
		func check(_ neighbourPosition: IntVec2, _ centerCluster: SnakeLevel_ClusterId) {
			guard emptyPositionSet.contains(neighbourPosition) else {
				return
			}
			guard let neighbourCluster: SnakeLevel_ClusterId = clusters.getValue(neighbourPosition) else {
				return
			}
			let neighbouringPositionButDifferentCluster: Bool = neighbourCluster != centerCluster
			if neighbouringPositionButDifferentCluster {
				let pair = SnakeLevel_ClusterPair.create(neighbourCluster, centerCluster)
				adjacentClusterPairs.insert(pair)
			}
		}
		for position in emptyPositionSet {
			guard let cluster: SnakeLevel_ClusterId = clusters.getValue(position) else {
				continue
			}
			check(position.offsetBy(dx: -1, dy: 0), cluster)
			check(position.offsetBy(dx: 1, dy: 0), cluster)
			check(position.offsetBy(dx: 0, dy: -1), cluster)
			check(position.offsetBy(dx: 0, dy: 1), cluster)
		}
		return adjacentClusterPairs
	}
}
