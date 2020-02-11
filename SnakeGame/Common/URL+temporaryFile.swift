// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

extension URL {
	internal static func temporaryFile(with prefix: String) -> URL {
		let uuid = UUID().uuidString
		let pathComponent = "\(prefix)-\(uuid)"
		return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(pathComponent)
	}
}
