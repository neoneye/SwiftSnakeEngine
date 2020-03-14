// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import GameplayKit

/// Deterministic random generator
///
/// The `GKMersenneTwisterRandomSource` has no accessor for the "seed".
/// For this reason it's necessary to keep track of the number of invocations of the random generator,
/// So that the same numbers can be reproduced. It's ugly to iterate lots of times until reaching the same "count".
///
/// IDEA: Instead of `GKMersenneTwisterRandomSource`, then use the "xorshift64" generator.
/// which has a settable "seed" parameter. This would eliminate the ulgy loop code with `GKMersenneTwisterRandomSource`.
/// http://vigna.di.unimi.it/ftp/papers/xorshift.pdf
public class SeededGenerator: RandomNumberGenerator {
	public private(set) var seed: UInt64
	public private(set) var count: UInt64
	private var generator: GKMersenneTwisterRandomSource

	public convenience init() {
		self.init(seed: 0)
	}

	public init(seed: UInt64) {
		self.seed = seed
		self.count = 0
		generator = GKMersenneTwisterRandomSource(seed: seed)
	}

	public func resetIfNeeded(seed: UInt64, count: UInt64) {
		if seed == self.seed && count == self.count {
			return
		}
		forceReset(seed: seed, count: count)
	}

	public func forceReset(seed: UInt64, count: UInt64) {
		self.seed = seed
		self.generator = GKMersenneTwisterRandomSource(seed: seed)
		self.count = count
		for _ in 0..<count {
			self.generator.nextInt()
		}
	}

	public func next<T>(upperBound: T) -> T where T : FixedWidthInteger, T : UnsignedInteger {
		defer {
			count += 1
		}
		return T(abs(generator.nextInt(upperBound: Int(upperBound))))
	}

	public func next<T>() -> T where T : FixedWidthInteger, T : UnsignedInteger {
		defer {
			count += 1
		}
		return T(abs(generator.nextInt()))
	}
}
