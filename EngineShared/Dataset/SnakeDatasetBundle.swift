// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakeDatasetBundleError: Error {
    case custom(message: String)
}

public class SnakeDatasetBundle {
    private class func snakeDatasetBundle() throws -> Bundle {
        let bundleName = "SnakeDataset.bundle"
        guard let bundleUrl: URL = Bundle(for: SnakeDatasetBundle.self).url(forResource: bundleName, withExtension: nil) else {
            throw SnakeDatasetBundleError.custom(message: "Cannot locate bundle: '\(bundleName)'")
        }
        guard let bundle: Bundle = Bundle(url: bundleUrl) else {
            throw SnakeDatasetBundleError.custom(message: "Unable to create bundle from url: '\(bundleUrl)'")
        }
        return bundle
    }

    public class func load(_ resourceName: String) throws -> Data {
        let bundle: Bundle = try snakeDatasetBundle()
        guard let dataUrl: URL = bundle.url(forResource: resourceName, withExtension: nil) else {
            let bundleUrlString = String(describing: bundle.resourceURL)
            throw SnakeDatasetBundleError.custom(message: "Unable to locate resource: '\(resourceName)' inside bundle at: '\(bundleUrlString)'")
        }
        guard let data = try? Data(contentsOf: dataUrl) else {
            throw SnakeDatasetBundleError.custom(message: "Unable to load data from url: \(dataUrl)")
        }
        return data
    }

    /// Returns an array of file URLs for all the `snakeDataset` contained in the bundle.
    public class func urls() throws -> [URL] {
        let bundle: Bundle = try snakeDatasetBundle()
        guard let urls: [URL] = bundle.urls(forResourcesWithExtension: "snakeDataset", subdirectory: nil) else {
            throw SnakeDatasetBundleError.custom(message: "Unable to get content of bundle")
        }
        return urls
    }
}
