// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import CryptoKit

extension Data {
    public var sha1: String {
		let iterator: Array<UInt8>.Iterator = Insecure.SHA1.hash(data: self).makeIterator()
		return iterator.map { String(format: "%02x", $0) }.joined()
    }
}
