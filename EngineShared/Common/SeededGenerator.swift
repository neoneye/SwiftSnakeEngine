// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public typealias SeededGenerator = LCRNG


/// Deterministic random generator
///
/// A linear congruential random number generator.
///
/// LCRNG is taken from the [swift-gen](https://github.com/pointfreeco/swift-gen) project.
public struct LCRNG: RandomNumberGenerator {
    public var seed: UInt64

    @inlinable
    public init(seed: UInt64) {
        self.seed = seed
    }

    @inlinable
    public mutating func next() -> UInt64 {
        seed = 2862933555777941757 &* seed &+ 3037000493
        return seed
    }
}
