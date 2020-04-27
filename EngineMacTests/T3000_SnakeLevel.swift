// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T3000_SnakeLevel: XCTestCase {

    func test0_adjacentClusterPairs() {
		do {
            let b = SnakeLevelBuilder(id: UUID(), size: UIntVec2(x: 3, y: 1))
			b.assignCluster(100, at: UIntVec2(x: 0, y: 0))
			b.installWall(at: UIntVec2(x: 1, y: 0))
			b.assignCluster(102, at: UIntVec2(x: 2, y: 0))
			let pairs: Set<SnakeLevel_ClusterPair> = b.computeAdjacentClusterPairs()
			XCTAssertTrue(pairs.isEmpty)
		}
		do {
			let b = SnakeLevelBuilder(id: UUID(), size: UIntVec2(x: 6, y: 1))
			b.assignCluster(100, at: UIntVec2(x: 0, y: 0))
			b.assignCluster(100, at: UIntVec2(x: 1, y: 0))
			b.assignCluster(101, at: UIntVec2(x: 2, y: 0))
			b.assignCluster(101, at: UIntVec2(x: 3, y: 0))
			b.assignCluster(102, at: UIntVec2(x: 4, y: 0))
			b.assignCluster(102, at: UIntVec2(x: 5, y: 0))
			let pairs: Set<SnakeLevel_ClusterPair> = b.computeAdjacentClusterPairs()
			XCTAssertEqual(pairs.count, 2)
			XCTAssertTrue(pairs.contains(SnakeLevel_ClusterPair.create(100, 101)))
			XCTAssertTrue(pairs.contains(SnakeLevel_ClusterPair.create(101, 102)))
		}
		do {
			let b = SnakeLevelBuilder(id: UUID(), size: UIntVec2(x: 2, y: 2))
			b.assignCluster(100, at: UIntVec2(x: 0, y: 0))
			b.assignCluster(101, at: UIntVec2(x: 1, y: 0))
			b.assignCluster(111, at: UIntVec2(x: 0, y: 1))
			b.assignCluster(110, at: UIntVec2(x: 1, y: 1))
			let pairs: Set<SnakeLevel_ClusterPair> = b.computeAdjacentClusterPairs()
			XCTAssertEqual(pairs.count, 4)
			XCTAssertTrue(pairs.contains(SnakeLevel_ClusterPair.create(100, 101)))
			XCTAssertTrue(pairs.contains(SnakeLevel_ClusterPair.create(101, 110)))
			XCTAssertTrue(pairs.contains(SnakeLevel_ClusterPair.create(110, 111)))
			XCTAssertTrue(pairs.contains(SnakeLevel_ClusterPair.create(111, 100)))
		}
    }

}
