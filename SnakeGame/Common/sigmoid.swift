// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

// Returns a value between 0 and 1
public func sigmoid(_ x: Float) -> Float {
	return 1.0 / (1.0 + exp(-x))
}
public func sigmoid(_ x: Double) -> Double {
	return 1.0 / (1.0 + exp(-x))
}

//sigmoid(-2) // 0.12
//sigmoid(-1) // 0.27
//sigmoid(0)  // 0.5
//sigmoid(1)  // 0.73
//sigmoid(2)  // 0.88


public func sigmoidDerived<T: FloatingPoint>(_ x: T) -> T {
	return x * (1 - x)
}

//sigmoidDerived(0.1)  // 0.09
//sigmoidDerived(0.25) // 0.188
//sigmoidDerived(0.5)  // 0.25
//sigmoidDerived(0.75) // 0.188
//sigmoidDerived(0.9)  // 0.09
