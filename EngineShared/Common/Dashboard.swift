// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Live visualization of what is going on inside the brain of the snake AI.
public class Dashboard {
    private init() {}

    public var url: URL = URL(string: "http://localhost:4000/")!

    public static let shared = Dashboard()

    /// Send a graphviz DOT file to the server.
    ///
    /// The server renders the DOT file as SVG and presents it on the dashboard.
    public func sendGraphvizData(uuid: UUID, preformattedText: String, dotfile: String) {
        let model = GraphvizRequestModel(
            uuid: uuid,
            preformattedText: preformattedText,
            dotfile: dotfile
        )

        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(model)
        } catch let error {
            log.error("Unable to convert model to json", error.localizedDescription)
            return
        }

        let graphvizUrl: URL = url.appendingPathComponent("graphviz")

        var request = URLRequest(url: graphvizUrl)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            if let theError = error {
                log.error("Response contains an error", String(describing: theError))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                log.error("Expected response to be of type HTTPURLResponse")
                return
            }
            let statusCode: Int = httpResponse.statusCode
            guard statusCode == 200 else {
                log.error("Expected statusCode 200, but got: \(statusCode)")
                return
            }
            //log.debug("success")
        })
        task.resume()
    }
}

fileprivate struct GraphvizRequestModel: Codable {
    var uuid: UUID
    var preformattedText: String
    var dotfile: String
}

