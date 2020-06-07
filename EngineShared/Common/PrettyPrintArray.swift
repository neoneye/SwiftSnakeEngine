// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public struct PrettyPrintArray {
    let prefixLength: UInt
    let suffixLength: UInt
    let separator: String
    let ellipsis: String

    public static let simple = PrettyPrintArray(prefixLength: 3, suffixLength: 3, separator: ",", ellipsis: "...")

    public func format<T>(_ positions: [T]) -> String {
        guard positions.count > Int(prefixLength + suffixLength) else {
            let p0: [String] = positions.map { String(describing: $0) }
            return p0.joined(separator: separator)
        }
        let a0: ArraySlice<T> = positions.prefix(Int(prefixLength))
        let b0: ArraySlice<T> = positions.suffix(Int(suffixLength))
        let a1: [String] = a0.map { String(describing: $0) }
        let b1: [String] = b0.map { String(describing: $0) }
        let ab: [String] = a1 + [ellipsis] + b1
        return ab.joined(separator: separator)
    }
}
