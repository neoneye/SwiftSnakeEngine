// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public struct SnakeFifo<T: Hashable>: Hashable {
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
		self.array = original.array
	}

	public init(array: Array<T>) {
		self.capacity = UInt(array.count)
		self.array = array
	}

	private init(capacity: UInt, array: Array<T>) {
		self.capacity = capacity
		self.array = array
	}

	public func map(_ transform: (T) throws -> T) rethrows -> SnakeFifo<T> {
		let newArray: [T] = try self.array.map {
			try transform($0)
		}
		return SnakeFifo<T>(capacity: self.capacity, array: newArray)
	}

	public mutating func removeAll() {
		capacity = 0
		purge()
	}

	public mutating func append(_ item: T) {
		array.append(item)
		purge()
	}

	public mutating func appendAndGrow(_ item: T) {
		capacity += 1
		array.append(item)
		purge()
	}

	public mutating func appendAndShrink(_ item: T) {
		if capacity >= 1 {
			capacity -= 1
		}
		array.append(item)
		purge()
	}

	private mutating func purge() {
		let diff: Int = self.array.count - Int(self.capacity)
		if diff >= 1 {
			array.removeFirst(diff)
		}
	}
}
