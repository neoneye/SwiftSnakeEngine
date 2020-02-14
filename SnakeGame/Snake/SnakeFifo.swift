// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeFifo<T: Hashable> {
	private var capacity: UInt
	public fileprivate (set) var array: [T]

	public init() {
		self.capacity = 0
		self.array = [T]()
	}

	public init(capacity: UInt, defaultValue: T) {
		self.capacity = capacity
		self.array = [T](repeating: defaultValue, count: Int(capacity))
	}

	public init(original: SnakeFifo<T>) {
		self.capacity = original.capacity
		self.array = [T](original.array)
	}

	public init(array: Array<T>) {
		self.capacity = UInt(array.count)
		self.array = [T](array)
	}

	private init(capacity: UInt, originalArray: Array<T>) {
		self.capacity = capacity
		self.array = [T](originalArray)
	}

	public func map(_ transform: (T) throws -> T) rethrows -> SnakeFifo<T> {
		let newArray: [T] = try self.array.map {
			try transform($0)
		}
		return SnakeFifo<T>(capacity: self.capacity, originalArray: newArray)
	}

	public func removeAll() {
		capacity = 0
		purge()
	}

	public func append(_ item: T) {
		array.append(item)
		purge()
	}

	public func appendAndGrow(_ item: T) {
		capacity += 1
		array.append(item)
		purge()
	}

	public func appendAndShrink(_ item: T) {
		if capacity >= 1 {
			capacity -= 1
		}
		array.append(item)
		purge()
	}

	private func purge() {
		let diff: Int = self.array.count - Int(self.capacity)
		if diff >= 1 {
			array.removeFirst(diff)
		}
	}
}

extension SnakeFifo: Equatable {
	public static func == (lhs: SnakeFifo, rhs: SnakeFifo) -> Bool {
		guard lhs.capacity == rhs.capacity else {
			return false
		}
		return lhs.array == rhs.array
	}
}

extension SnakeFifo: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(capacity)
		hasher.combine(array)
	}
}
