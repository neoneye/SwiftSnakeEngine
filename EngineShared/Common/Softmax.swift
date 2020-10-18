// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

/// https://en.wikipedia.org/wiki/Softmax_function
extension Array where Element == Float {
    public var softmax: [Float] {
        var exponential = [Float](repeating: 0, count: self.count)
        var sum: Float = 0
        for index in 0..<self.count {
            let value: Float = exp(self[index])
            exponential[index] = value
            sum += value
        }
        for index in 0..<self.count {
            exponential[index] /= sum
        }
        return exponential
    }
}
