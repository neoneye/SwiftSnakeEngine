// MIT license. Copyright (c) 2020 TriangleDraw. All rights reserved.

public func remap<T: FloatingPoint>(_ value: T, _ a: T, _ b: T, _ c: T, _ d: T) -> T {
	return c + (d - c) * (value - a) / (b - a)
}

//remap(-1.0, -1.0, 1.0, -10.0, 10.0) // -10
//remap(-0.5, -1.0, 1.0, -10.0, 10.0) // -5
//remap(0.0, -1.0, 1.0, -10.0, 10.0)  // 0
//remap(0.5, -1.0, 1.0, -10.0, 10.0)  // 5
//remap(1.0, -1.0, 1.0, -10.0, 10.0)  // 10
