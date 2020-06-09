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
}
