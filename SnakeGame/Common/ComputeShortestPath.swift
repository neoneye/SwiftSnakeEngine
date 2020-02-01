// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class ComputeShortestPath {
	public class func compute(availablePositions: [IntVec2], startPosition: IntVec2, targetPosition: IntVec2) -> [IntVec2] {
//		return compute1(availablePositions: availablePositions, startPosition: startPosition, targetPosition: targetPosition)
		return compute2(availablePositions: availablePositions, startPosition: startPosition, targetPosition: targetPosition)
	}

	// Don't care about the number of turns
	// Prefers positions that isn't adjacent to a wall
	public class func compute1(availablePositions: [IntVec2], startPosition: IntVec2, targetPosition: IntVec2) -> [IntVec2] {

		var positionToIndex: [IntVec2: Int] = [:]
		for (index, position) in availablePositions.enumerated() {
			positionToIndex[position] = index
		}
		guard let sourceIndex = positionToIndex[startPosition] else {
			print("ERROR: found no index for startPosition")
			return []
		}
		guard let targetIndex = positionToIndex[targetPosition] else {
			print("ERROR: found no index for targetPosition")
			return []
		}

		typealias VertexIntVec2 = Vertex<IntVec2>
		var vertexArray: [VertexIntVec2] = []
		let graph = AdjacencyMatrixGraph<IntVec2>()

		for position: IntVec2 in availablePositions {
			let vertex: VertexIntVec2 = graph.createVertex(position)
			vertexArray.append(vertex)
		}

		// Create horizontal edges
		for (index, position) in availablePositions.enumerated() {
			let position1 = position.offsetBy(dx: 1, dy: 0)
			guard let index1 = positionToIndex[position1] else {
				continue
			}
			var edgeCount: Int = 0
			var edgeWeight: Double = 1
			func countEdge2(dx1: Int32, dy1: Int32, weight1: Int, dx2: Int32, dy2: Int32, weight2: Int, dx3: Int32, dy3: Int32, weight3: Int) {
				let position1 = position.offsetBy(dx: dx1, dy: dy1)
				guard positionToIndex.keys.contains(position1) else {
					edgeWeight += Double(weight1 + weight2 + weight3)
					return
				}
				edgeCount += 1
				let position2 = position.offsetBy(dx: dx2, dy: dy2)
				guard positionToIndex.keys.contains(position2) else {
					edgeWeight += Double(weight2 + weight3)
					return
				}
				edgeCount += 1
				let position3 = position.offsetBy(dx: dx3, dy: dy3)
				guard positionToIndex.keys.contains(position3) else {
					edgeWeight += Double(weight3)
					return
				}
				edgeCount += 1
			}
			countEdge2(dx1: -1, dy1: -1, weight1: 1, dx2: -2, dy2: -1, weight2: 10, dx3: -3, dy3: -1, weight3: 10)
			countEdge2(dx1: -1, dy1:  0, weight1: 1, dx2: -2, dy2:  0, weight2: 15, dx3: -3, dy3:  0, weight3: 40)
			countEdge2(dx1: -1, dy1:  1, weight1: 1, dx2: -2, dy2:  1, weight2: 10, dx3: -3, dy3:  1, weight3: 10)
			let weight01: Double = edgeWeight

			edgeCount = 0
			edgeWeight = 1
			countEdge2(dx1: 2, dy1: -1, weight1: 1, dx2: 3, dy2: -1, weight2: 10, dx3: 4, dy3: -1, weight3: 10)
			countEdge2(dx1: 2, dy1:  0, weight1: 1, dx2: 3, dy2:  0, weight2: 15, dx3: 4, dy3:  0, weight3: 40)
			countEdge2(dx1: 2, dy1:  1, weight1: 1, dx2: 3, dy2:  1, weight2: 10, dx3: 4, dy3:  1, weight3: 10)
			let weight10: Double = edgeWeight

			let vertex0: VertexIntVec2 = vertexArray[index]
			let vertex1: VertexIntVec2 = vertexArray[index1]
			graph.addDirectedEdge(vertex0, to: vertex1, withWeight: weight01)
			graph.addDirectedEdge(vertex1, to: vertex0, withWeight: weight10)
		}

		// Create vertical edges
		for (index, position) in availablePositions.enumerated() {
			let position1 = position.offsetBy(dx: 0, dy: 1)
			guard let index1 = positionToIndex[position1] else {
				continue
			}
			var edgeCount: Int = 0
			var edgeWeight: Double = 1
			func countEdge2(dx1: Int32, dy1: Int32, weight1: Int, dx2: Int32, dy2: Int32, weight2: Int, dx3: Int32, dy3: Int32, weight3: Int) {
				let position1 = position.offsetBy(dx: dx1, dy: dy1)
				guard positionToIndex.keys.contains(position1) else {
					edgeWeight += Double(weight1 + weight2 + weight3)
					return
				}
				edgeCount += 1
				let position2 = position.offsetBy(dx: dx2, dy: dy2)
				guard positionToIndex.keys.contains(position2) else {
					edgeWeight += Double(weight2 + weight3)
					return
				}
				edgeCount += 1
				let position3 = position.offsetBy(dx: dx3, dy: dy3)
				guard positionToIndex.keys.contains(position3) else {
					edgeWeight += Double(weight3)
					return
				}
				edgeCount += 1
			}
			countEdge2(dx1: -1, dy1: -1, weight1: 1, dx2: -1, dy2: -2, weight2: 10, dx3: -1, dy3: -3, weight3: 10)
			countEdge2(dx1:  0, dy1: -1, weight1: 1, dx2:  0, dy2: -2, weight2: 15, dx3:  0, dy3: -3, weight3: 40)
			countEdge2(dx1:  1, dy1: -1, weight1: 1, dx2:  1, dy2: -2, weight2: 10, dx3:  1, dy3: -3, weight3: 10)
			let weight01: Double = edgeWeight

			edgeCount = 0
			edgeWeight = 1
			countEdge2(dx1: -1, dy1: 2, weight1: 1, dx2: -1, dy2: 3, weight2: 10, dx3: -1, dy3: 4, weight3: 10)
			countEdge2(dx1:  0, dy1: 2, weight1: 1, dx2:  0, dy2: 3, weight2: 15, dx3:  0, dy3: 4, weight3: 40)
			countEdge2(dx1:  1, dy1: 2, weight1: 1, dx2:  1, dy2: 3, weight2: 10, dx3:  1, dy3: 4, weight3: 10)
			let weight10: Double = edgeWeight

			let vertex0: VertexIntVec2 = vertexArray[index]
			let vertex1: VertexIntVec2 = vertexArray[index1]
			graph.addDirectedEdge(vertex0, to: vertex1, withWeight: weight01)
			graph.addDirectedEdge(vertex1, to: vertex0, withWeight: weight10)
		}


		let sourceVertex: VertexIntVec2 = vertexArray[sourceIndex]
		let targetVertex: VertexIntVec2 = vertexArray[targetIndex]

		guard let result: BellmanFordResult<IntVec2> = BellmanFord<IntVec2>.apply(graph, source: sourceVertex) else {
			print("ERROR: expected a result from BellmanFord, but got nil")
			return []
		}

		guard let path: [IntVec2] = result.path(to: targetVertex, inGraph: graph) else {
			print("ERROR: expected a path from BellmanFord, but got nil")
			return []
		}
		return path
	}

	// Find the shortest path AND prefers making as few turns as possible
	public class func compute2(availablePositions: [IntVec2], startPosition: IntVec2, targetPosition: IntVec2) -> [IntVec2] {

		var positionToIndex: [IntVec2: Int] = [:]
		for (index, position) in availablePositions.enumerated() {
			positionToIndex[position] = index
		}
		guard let sourceIndex = positionToIndex[startPosition] else {
			print("ERROR: found no index for startPosition")
			return []
		}
		guard let targetIndex = positionToIndex[targetPosition] else {
			print("ERROR: found no index for targetPosition")
			return []
		}

		typealias VertexIntVec2 = Vertex<IntVec2>
		var vertexArray: [VertexIntVec2] = []
		let graph = AdjacencyMatrixGraph<IntVec2>()

		for position: IntVec2 in availablePositions {
			let vertex: VertexIntVec2 = graph.createVertex(position)
			vertexArray.append(vertex)
		}

		for (index, position) in availablePositions.enumerated() {
			func addEdges(dx: Int32, dy: Int32) {
				var position0: IntVec2 = position
				while true {
					let position1 = position0.offsetBy(dx: dx, dy: dy)
					guard let index1 = positionToIndex[position1] else {
						return
					}
					let vertex0: VertexIntVec2 = vertexArray[index]
					let vertex1: VertexIntVec2 = vertexArray[index1]
					let pair: (VertexIntVec2, VertexIntVec2) = (vertex0, vertex1)
					graph.addUndirectedEdge(pair, withWeight: 1)
					position0 = position1
				}
			}
			addEdges(dx: 1, dy: 0)
			addEdges(dx: 0, dy: 1)
		}

		let sourceVertex: VertexIntVec2 = vertexArray[sourceIndex]
		let targetVertex: VertexIntVec2 = vertexArray[targetIndex]

		// IDEA: build this graph only once for a SnakeLevel, and reuse it afterward
		guard let result: BellmanFordResult<IntVec2> = BellmanFord<IntVec2>.apply(graph, source: sourceVertex) else {
			print("ERROR: expected a result from BellmanFord, but got nil")
			return []
		}

		guard let path: [IntVec2] = result.path(to: targetVertex, inGraph: graph) else {
			print("ERROR: expected a path from BellmanFord, but got nil")
			return []
		}

		return insertMissingSteps(path)
	}

	class func insertMissingSteps(_ path: [IntVec2]) -> [IntVec2] {
		guard path.count >= 2 else {
			return path
		}

		var resultPath = [IntVec2]()
		var range = path.indices
		range.removeLast()
		for i in range {
			let a = path[i]
			let b = path[i + 1]
			guard a != b else {
				print("ERROR: expected unique positions in path, but encountered duplicates. \(path)")
				return []
			}

			let dx: Int = Int(b.x) - Int(a.x)
			let dy: Int = Int(b.y) - Int(a.y)

			if dx != 0 && dy == 0 {
				// walk horizontal
				let step: Int32 = (dx >= 0) ? 1 : -1
				var x: Int32 = a.x
				while x != b.x {
					resultPath.append(IntVec2(x: x, y: a.y))
					x += step
				}
				continue
			}

			if dx == 0 && dy != 0 {
				// walk vertical
				let step: Int32 = (dy >= 0) ? 1 : -1
				var y: Int32 = a.y
				while y != b.y {
					resultPath.append(IntVec2(x: a.x, y: y))
					y += step
				}
				continue
			}

			print("ERROR: expected positions to change along the x/y axis, but this path is diagonal. \(path)")
			return []
		}
		resultPath.append(path.last!)
		return resultPath
	}
}
