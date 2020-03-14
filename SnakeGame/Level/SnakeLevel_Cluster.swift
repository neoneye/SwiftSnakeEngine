// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public typealias SnakeLevel_ClusterId = UInt8

public struct SnakeLevel_ClusterPair {
	public let low: SnakeLevel_ClusterId
	public let high: SnakeLevel_ClusterId

	/// The order of the the parameters does matter!
	private init(low: SnakeLevel_ClusterId, high: SnakeLevel_ClusterId) {
		assert(low <= high)
		self.low = low
		self.high = high
	}

	/// The order of the the parameters doesn't matter.
	/// We assume it's roughly the same distance from A to B, as it is from B to A.
	/// Thus both A and B gets merged into a single key, by sorting them.
	public static func create(_ cluster0: SnakeLevel_ClusterId, _ cluster1: SnakeLevel_ClusterId) -> SnakeLevel_ClusterPair {
		let low: SnakeLevel_ClusterId
		let high: SnakeLevel_ClusterId
		if cluster0 <= cluster1 {
			low = cluster0
			high = cluster1
		} else {
			low = cluster1
			high = cluster0
		}
		return SnakeLevel_ClusterPair(low: low, high: high)
	}
}

extension SnakeLevel_ClusterPair: Equatable {

	/// Returns a Boolean value indicating whether two values are equal.
	///
	/// Equality is the inverse of inequality. For any values `a` and `b`,
	/// `a == b` implies that `a != b` is `false`.
	///
	/// - Parameters:
	///   - lhs: A value to compare.
	///   - rhs: Another value to compare.
	public static func == (lhs: SnakeLevel_ClusterPair, rhs: SnakeLevel_ClusterPair) -> Bool {
		guard lhs.low == rhs.low else {
			return false
		}
		guard lhs.high == rhs.high else {
			return false
		}
		return true
	}
}

extension SnakeLevel_ClusterPair: Hashable {
	/// Hashes the `low` and `high` components of this value by feeding them into the given hasher.
	public func hash(into hasher: inout Hasher) {
		self.low.hash(into: &hasher)
		self.high.hash(into: &hasher)
	}
}

extension SnakeLevel_ClusterPair: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.low == rhs.low {
			return lhs.high < rhs.high
		} else {
			return lhs.low < rhs.low
		}
	}
}
