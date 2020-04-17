// MIT license. Copyright (c) 2020 TriangleDraw. All rights reserved.

/// A vector of 2 unsigned integers.
///
/// This struct is inspired by Metal's `intvec2` type and GLSL's `ivec2` type.
public struct UIntVec2: Hashable {
	public var x: UInt32
	public var y: UInt32

	public init(x: UInt32, y: UInt32) {
		self.x = x
		self.y = y
	}
}

extension UIntVec2 {
	/// Returns a new vector that is offset from that of the source vector.
	///
	/// - Parameters:
	///   - dx: The offset value for the `x`-coordinate.
	///   - dy: The offset value for the `y`-coordinate.
	public func offsetBy(dx: UInt32, dy: UInt32) -> UIntVec2 {
		return UIntVec2(x: self.x + dx, y: self.y + dy)
	}

	/// The vector with the value `(0, 0)`.
	public static var zero: UIntVec2 {
		return UIntVec2(x: 0, y: 0)
	}
}

extension UIntVec2: CustomDebugStringConvertible {
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

extension UIntVec2: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.y == rhs.y {
			return lhs.x < rhs.x
		} else {
			return lhs.y < rhs.y
		}
	}
}

extension UIntVec2 {
	public var intVec2: IntVec2 {
		return IntVec2(x: Int32(self.x), y: Int32(self.y))
	}
}
