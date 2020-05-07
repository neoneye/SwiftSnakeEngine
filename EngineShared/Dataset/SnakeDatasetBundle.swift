// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

class SnakeDatasetBundle {
    public enum LoadError: Error {
        case runtimeError(message: String)
    }

    public class func load(_ resourceName: String) throws -> Data {
        let bundleName = "SnakeDataset.bundle"
        guard let bundleUrl: URL = Bundle(for: SnakeDatasetBundle.self).url(forResource: bundleName, withExtension: nil) else {
            throw LoadError.runtimeError(message: "Cannot locate bundle: '\(bundleName)'")
        }
        guard let bundle: Bundle = Bundle(url: bundleUrl) else {
            throw LoadError.runtimeError(message: "Unable to create bundle from url: '\(bundleUrl)'")
        }
        guard let dataUrl: URL = bundle.url(forResource: resourceName, withExtension: nil) else {
            throw LoadError.runtimeError(message: "Unable to locate resource: '\(resourceName)' inside bundle at: '\(bundleUrl)'")
        }
        guard let data = try? Data(contentsOf: dataUrl) else {
            throw LoadError.runtimeError(message: "Unable to load data from url: \(dataUrl)")
        }
        return data
    }
}
