// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

extension Array where Element == IntVec2 {
    public func toPath() -> [IntVec2] {
        guard ValidateDistance.distanceIsOne(self) else {
            return []
        }
        var result = [IntVec2]()
        var lastDiff = IntVec2.zero
        for (index, position) in self.enumerated() {
            if index == 0 {
                result.append(position)
                continue
            }
            let previousPosition: IntVec2 = result[result.count-1]
            let newDiff: IntVec2 = position.subtract(previousPosition)
            if newDiff == lastDiff {
                result[result.count-1] = position
            } else {
                lastDiff = newDiff
                result.append(position)
            }
        }
        return result
    }
}

