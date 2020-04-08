// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
public class Array2<T> {
	public let size: UIntVec2
	private var array: [T]

	public init(size: UIntVec2, defaultValue: T) {
		self.size = size
		let capacity = Int(size.x * size.y)
		self.array = [T](repeating: defaultValue, count: Int(capacity))
	}

	public func setValue(_ value: T, at position: IntVec2) {
		guard let position1 = position.uintVec2() else {
			return
		}
		setValue(value, at: position1)
	}

	public func setValue(_ value: T, at position: UIntVec2) {
		guard position.x < size.x && position.y < size.y else {
			return
		}
		let index = Int(position.y * size.x + position.x)
		array[index] = value
	}

	public func getValue(_ position: IntVec2) -> T? {
		guard let position1 = position.uintVec2() else {
			return nil
		}
		return getValue(position1)
	}

	public func getValue(_ position: UIntVec2) -> T? {
		guard position.x < size.x && position.y < size.y else {
			return nil
		}
		let index = Int(position.y * size.x + position.x)
		return array[index]
	}
}
