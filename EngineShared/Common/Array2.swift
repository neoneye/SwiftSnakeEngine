// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

/// Two-dimensional array
public class Array2<T> {
	public let size: UIntVec2
	private var array: [T]

	public init(size: UIntVec2, defaultValue: T) {
		self.size = size
		let capacity = Int(size.x * size.y)
		self.array = [T](repeating: defaultValue, count: Int(capacity))
	}

    private init(size: UIntVec2, array: [T]) {
        self.size = size
        self.array = array
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

    public func indexIsValid(x: Int32, y: Int32) -> Bool {
        x >= 0 && y >= 0 && x < size.x && y < size.y
    }

    private func offsetForIndex(x: UInt32, y: UInt32) -> UInt32 {
        y * size.x + x
    }

    public subscript(x: Int32, y: Int32) -> T {
        get {
            assert(indexIsValid(x: x, y: y))
            let offset: UInt32 = offsetForIndex(x: UInt32(x), y: UInt32(y))
            return array[Int(offset)]
        }
        set {
            assert(indexIsValid(x: x, y: y))
            let offset: UInt32 = offsetForIndex(x: UInt32(x), y: UInt32(y))
            array[Int(offset)] = newValue
        }
    }

    public typealias FormatBlock = (T, UIntVec2) -> String

    /// Pretty print all the cells of the array.
    public func format(columnSeparator: String=",", rowSeparator: String="\n", _ block: @escaping FormatBlock) -> String {
        var rows = [String]()
        for y: UInt32 in 0..<size.y {
            var columns = [String]()
            for x: UInt32 in 0..<size.x {
                let position = UIntVec2(x: x, y: y)
                guard let value: T = getValue(position) else {
                    fatalError("Expected non-nil, but got nil. Position inside the grid is always supposed to return non-nil.")
                }
                let valueString: String = block(value, position)
                columns.append(valueString)
            }
            rows.append(columns.joined(separator: columnSeparator))
        }
        return rows.joined(separator: rowSeparator)
    }

    public var flipX: Array2<T> {
        let newArray = Array2(size: self.size, array: [T](self.array))
        for y in 0..<Int32(self.size.y) {
            for x in 0..<Int32(self.size.x) {
                let sourcePosition = IntVec2(x: x, y: y)
                let destinationPosition = IntVec2(x: Int32(self.size.x) - x - 1, y: y)
                guard let value: T = getValue(sourcePosition) else {
                    fatalError("Expected non-nil, but got nil. Position inside the grid is always supposed to return non-nil.")
                }
                newArray.setValue(value, at: destinationPosition)
            }
        }
        return newArray
    }

    public var flipY: Array2<T> {
        let newArray = Array2(size: self.size, array: [T](self.array))
        for y in 0..<Int32(self.size.y) {
            for x in 0..<Int32(self.size.x) {
                let sourcePosition = IntVec2(x: x, y: y)
                let destinationPosition = IntVec2(x: x, y: Int32(self.size.y) - y - 1)
                guard let value: T = getValue(sourcePosition) else {
                    fatalError("Expected non-nil, but got nil. Position inside the grid is always supposed to return non-nil.")
                }
                newArray.setValue(value, at: destinationPosition)
            }
        }
        return newArray
    }
}
