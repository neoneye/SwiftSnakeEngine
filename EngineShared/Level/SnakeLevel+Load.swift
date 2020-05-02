// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftCSV

extension SnakeLevel {
	/// Creates a `SnakeLevel` by parsing  a `"Level 123.csv"` file and an optional `"Level 123.cache"`file.
	///
	/// Looks for a corresponding `.cache` file. It will generates a `.cache` file whenever the `.csv` file has been changed.
	/// This `.cache` file is intended to be placed in the same folder as the `.csv` file, so that on next run the cached data will be used.
	public class func load(_ resourceName: String) -> SnakeLevel {
		let bundleName = "SnakeLevels.bundle"
		guard let bundleUrl: URL = Bundle(for: SnakeLevel.self).url(forResource: bundleName, withExtension: nil) else {
            log.error("Cannot locate bundle: '\(bundleName)'")
			fatalError()
		}
		guard let bundle: Bundle = Bundle(url: bundleUrl) else {
			log.error("Unable to create bundle from url: '\(bundleUrl)'")
			fatalError()
		}
		guard let csvUrl: URL = bundle.url(forResource: resourceName, withExtension: nil) else {
			log.error("Unable to locate resource: '\(resourceName)' inside bundle at: '\(bundleUrl)'")
			fatalError()
		}
		guard let csvData = try? Data(contentsOf: csvUrl) else {
			log.error("Unable to load data from url: \(csvUrl)")
			fatalError()
		}
		guard let content = String(data: csvData, encoding: .utf8) else {
			log.error("Expected utf8 string, but got something else. url: \(csvUrl)")
			fatalError()
		}
		guard let csv: CSV = try? CSV(string: content, delimiter: ",", loadColumns: false) else {
			log.error("Unable to load CSV. url: \(csvUrl)")
			fatalError()
		}
		let csvChecksum: String = csvData.sha1

        guard let uuidString: String = csv.header.first else {
            log.error("Expected level csv header to start with an UUID string. url: \(csvUrl)")
            fatalError()
        }
        guard let uuid = UUID(uuidString: uuidString) else {
            log.error("Expected level csv header to start with an valid UUID. url: \(csvUrl)")
            fatalError()
        }

		let cacheUrl: URL = csvUrl.deletingPathExtension().appendingPathExtension("cache")
		var cacheModel: SnakeLevelCacheModel?
		if let cacheData: Data = try? Data(contentsOf: cacheUrl) {
			if let model = try? SnakeLevelCacheModel(serializedData: cacheData) {
				if model.sha1 == csvChecksum {
					//log.debug("The cached data is syncronized")
					cacheModel = model
				} else {
                    log.warning("Will generate a new cache file. The checksum is out-of-sync for the current cache file at: \(cacheUrl)")
				}
			} else {
				log.warning("Will generate a new cache file. Unable to load the current cache file at: \(cacheUrl)")
			}
		} else {
            log.info("Will generate a new cache file. There is no cache at: \(cacheUrl)")
		}

		let rows: [[String]] = csv.enumeratedRows.reversed()
		let height = UInt32(rows.count)
		guard height >= 3 else {
            log.error("Expected level height to be 3 or greater")
			fatalError()
		}
		let width = UInt32(rows[0].count)
		guard width >= 3 else {
			log.error("Expected level width to be 3 or greater")
			fatalError()
		}
        let builder = SnakeLevelBuilder(id: uuid, size: UIntVec2(x: width, y: height))

		func modifyCell(_ token: String, at position: UIntVec2) {
			guard !token.isEmpty else {
				return
			}
			let s0: String = token.getCharacterAt(0)
			switch s0 {
			case "W": // wall
				builder.installWall(at: position)
			case "F": // food
				builder.initialFoodPosition = position
			case "P": // player
				guard token.count == 4 else {
					log.error("Expected player token to have format similar to: 'P1R5', 'P2L3', but got something with a different length")
					return
				}
				// player id: "1" or "2"
				let playerIdString: String = token.getCharacterAt(1)
				// head direction: "U"=up, "L"=left, "R"=right, "D"=down
				let headDirectionString: String = token.getCharacterAt(2)
				// snake length: "3"
				let snakeLengthString: String = token.getCharacterAt(3)
				var headDirection: SnakeHeadDirection
				switch headDirectionString {
				case "U":
					headDirection = .up
				case "L":
					headDirection = .left
				case "D":
					headDirection = .down
				default:
					headDirection = .right
				}
				let length: UInt = UInt(snakeLengthString) ?? 2
				if playerIdString == "1" {
                    builder.player1_body = SnakeBody.create(
                        position: position.intVec2,
                        headDirection: headDirection,
                        length: length
                    )
				}
				if playerIdString == "2" {
                    builder.player2_body = SnakeBody.create(
                        position: position.intVec2,
                        headDirection: headDirection,
                        length: length
                    )
				}
			case "C": // the cluster that this cell belongs to
				let integerString: String = String(token.dropFirst())
				guard let clusterId = UInt8(integerString) else {
					log.error("Expected a number in range 0..255, but got '\(integerString)'. Unable to parse token '\(token)' for position: \(position)")
					return
				}
				builder.assignCluster(clusterId, at: position)
			default:
				log.error("Encountered unknown token: '\(token)'  for position: \(position)")
			}
		}
		
		for (y, columns) in rows.enumerated() {
			guard width == columns.count else {
				log.error("Inconsistent number of columns in the CSV file. Expected \(width), but got \(columns.count)")
				fatalError()
			}
			for (x, cellContent) in columns.enumerated() {
				let cellTokens: [String] = cellContent.split(separator: " ").map { String($0) }
				let cellPosition = UIntVec2(x: UInt32(x), y: UInt32(y))
				for cellToken in cellTokens {
					modifyCell(cellToken, at: cellPosition)
				}
			}
		}

		if let model: SnakeLevelCacheModel = cacheModel {
			var distanceBetweenClusters = [SnakeLevel_ClusterPair: Int]()
			for distanceKeyValuePair in model.distances {
				let clusterPair = SnakeLevel_ClusterPair.create(UInt8(distanceKeyValuePair.keyLow), UInt8(distanceKeyValuePair.keyHigh))
				distanceBetweenClusters[clusterPair] = Int(distanceKeyValuePair.valueDistance)
			}
			builder.precomputed_distanceBetweenClusters = distanceBetweenClusters
            log.debug("Loaded \(distanceBetweenClusters.count) precomputed distances for input file '\(resourceName)'")
		}

		let resultLevel: SnakeLevel = builder.level()

		if cacheModel == nil {
            log.debug("Precomputing cache data for input file '\(resourceName)'")
			let pairs: [SnakeLevel_ClusterPair] = Array<SnakeLevel_ClusterPair>(resultLevel.distanceBetweenClusters.keys).sorted()
			var distanceKeyValuePairs = [SnakeLevelCacheModelDistanceKeyValuePair]()
			for pair in pairs {
				guard let distance: Int = resultLevel.distanceBetweenClusters[pair] else {
					continue
				}
				let distanceKeyValuePair = SnakeLevelCacheModelDistanceKeyValuePair.with {
					$0.keyLow = UInt32(pair.low)
					$0.keyHigh = UInt32(pair.high)
					$0.valueDistance = Int32(distance)
				}
				distanceKeyValuePairs.append(distanceKeyValuePair)
			}

			let newCacheModel = SnakeLevelCacheModel.with {
				$0.sha1 = csvChecksum
				$0.distances = distanceKeyValuePairs
			}

			// Serialize to binary protobuf format
			if let binaryData: Data = try? newCacheModel.serializedData() {
				let temporaryFileUrl: URL = URL.temporaryFile(prefixes: ["snakegame", "levelcache"], suffixes: [])
				do {
					try binaryData.write(to: temporaryFileUrl)
				} catch {
					log.error("Failed to save cache file at: '\(temporaryFileUrl)' for input file '\(resourceName)', error: \(error)")
					fatalError()
				}
                log.debug("Successfully saved a cache file at: '\(temporaryFileUrl)' for input file '\(resourceName)'.")
			} else {
				log.error("Unable to serialize the new cache model, for input file '\(resourceName)'.")
			}
		}

		return resultLevel
	}
}

extension String {
	fileprivate func getCharacterAt(_ i: Int) -> String {
		return String(self[index(startIndex, offsetBy: i)])
	}
}
