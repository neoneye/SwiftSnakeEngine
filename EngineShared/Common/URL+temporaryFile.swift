// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

extension URL {
    internal static func temporaryFile(prefixes: [String], uuid: UUID? = nil, suffixes: [String], pathExtension: String? = nil) -> URL {
		let uuidString: String = (uuid ?? UUID()).uuidString
		let components: [String] = prefixes + [uuidString] + suffixes
		let pathComponent = components.joined(separator: "-")
        var url: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(pathComponent)
        if let pathExtensionUnwrapped: String = pathExtension {
            url = url.appendingPathExtension(pathExtensionUnwrapped)
        }
        return url
	}
}
