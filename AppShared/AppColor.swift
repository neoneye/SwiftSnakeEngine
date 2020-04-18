// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import SpriteKit

enum AppColor: String {
    case levelSelector_border
}

extension AppColor {
    var color: Color {
        return Color(self.rawValue)
    }

    var skColor: SKColor {
        return SKColor(named: self.rawValue) ?? SKColor.red
    }
}
