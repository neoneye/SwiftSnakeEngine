// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftySound

enum SoundItem: String, CaseIterable {
    case snake_dies
    case snake_eats
    case snake_step
}

extension SoundItem {
    func play() {
        SoundManager.shared.playSound(for: self)
    }

    fileprivate var url: URL {
        guard let url: URL = Bundle.main.url(forResource: self.rawValue, withExtension: "wav") else {
            fatalError("Unable to find file for SoundItem. '\(self)'")
        }
        return url
    }
}

class SoundManager {
    static let shared = SoundManager()

    fileprivate let dict: [SoundItem: Sound]

    private init() {
        var dict = [SoundItem: Sound]()
        for soundItem in SoundItem.allCases {
            let url: URL = soundItem.url
            guard let sound: Sound = Sound(url: url) else {
                fatalError("Unable to create Sound instance for SoundItem. '\(soundItem)'")
            }
            dict[soundItem] = sound
        }
        self.dict = dict
    }

    fileprivate func playSound(for soundItem: SoundItem) {
        dict[soundItem]?.play()
    }
}
