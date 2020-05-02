// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

class SnakeDatasetBundle {
    public class func load(_ resourceName: String) -> Data {
        let bundleName = "SnakeDataset.bundle"
        guard let bundleUrl: URL = Bundle(for: SnakeDatasetBundle.self).url(forResource: bundleName, withExtension: nil) else {
            log.error("Cannot locate bundle: '\(bundleName)'")
            fatalError()
        }
        guard let bundle: Bundle = Bundle(url: bundleUrl) else {
            log.error("Unable to create bundle from url: '\(bundleUrl)'")
            fatalError()
        }
        guard let dataUrl: URL = bundle.url(forResource: resourceName, withExtension: nil) else {
            log.error("Unable to locate resource: '\(resourceName)' inside bundle at: '\(bundleUrl)'")
            fatalError()
        }
        guard let data = try? Data(contentsOf: dataUrl) else {
            log.error("Unable to load data from url: \(dataUrl)")
            fatalError()
        }
        return data
    }
}
