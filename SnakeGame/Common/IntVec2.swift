// MIT license. Copyright (c) 2020 TriangleDraw. All rights reserved.

/// A vector of 2 signed integers.
///
/// This struct is inspired by Metal's `intvec2` type and GLSL's `ivec2` type.
public struct IntVec2: Hashable {
	public var x: Int32
	public var y: Int32

	public init(x: Int32, y: Int32) {
		self.x = x
		self.y = y
	}
}

extension IntVec2 {
	/// Returns a new vector that is offset from that of the source vector.
	///
	/// - Parameters:
	///   - dx: The offset value for the `x`-coordinate.
	///   - dy: The offset value for the `y`-coordinate.
	public func offsetBy(dx: Int32, dy: Int32) -> IntVec2 {
		return IntVec2(x: self.x + dx, y: self.y + dy)
	}

	/// The vector with the value `(0, 0)`.
	public static var zero: IntVec2 {
		return IntVec2(x: 0, y: 0)
	}

	/// The distance between two points measured along axes at right angles.
	public func manhattanDistance(_ other: IntVec2) -> UInt32 {
		let dx: UInt32 = UInt32(abs(self.x - other.x))
		let dy: UInt32 = UInt32(abs(self.y - other.y))
		return dx + dy
	}
}

extension IntVec2: CustomDebugStringConvertible {
	/// A textual representation of this instance, suitable for debugging.
	///
	/// Calling this property directly is discouraged. Instead, convert an
	/// instance of any type to a string by using the `String(reflecting:)`
	/// initializer. This initializer works with any type, and uses the custom
	/// `debugDescription` property for types that conform to
	/// `CustomDebugStringConvertible`:
	///
	///     struct Point: CustomDebugStringConvertible {
	///         let x: Int, y: Int
	///
	///         var debugDescription: String {
	///             return "(\(x), \(y))"
	///         }
	///     }
	///
	///     let p = Point(x: 21, y: 30)
	///     let s = String(reflecting: p)
	///     print(s)
	///     // Prints "(21, 30)"
	///
	/// The conversion of `p` to a string in the assignment to `s` uses the
	/// `Point` type's `debugDescription` property.
	public var debugDescription: String {
		return "(\(x), \(y))"
	}
}

extension IntVec2: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.y == rhs.y {
			return lhs.x < rhs.x
		} else {
			return lhs.y < rhs.y
		}
	}
}

extension IntVec2 {
	public func uintVec2() -> UIntVec2? {
		guard self.x >= 0 && self.y >= 0 else {
			return nil
		}
		return UIntVec2(x: UInt32(self.x), y: UInt32(self.y))
	}
}
