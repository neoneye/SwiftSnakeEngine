// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import SpriteKit

#if os(macOS)
import Cocoa
#endif

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

enum AppColor: String {
    case levelSelector_background
    case levelSelector_border
    case player1_plannedPath
    case player2_plannedPath
    case player1_snakeBody
    case player2_snakeBody
    case exitGameButton_fill
    case exitGameButton_text
}

extension AppColor {
    var color: Color {
        return Color(self.rawValue)
    }

    #if os(macOS)
    var nsColor: NSColor {
        guard let color0 = NSColor(named: self.rawValue) else {
            log.error("Cannot find color in xcassets. \(self)")
            return NSColor.red
        }
        guard let color1: NSColor = color0.usingColorSpace(.deviceRGB) else {
            log.error("Cannot convert color to rgb colorspace. \(self)")
            return NSColor.red
        }
        return color1
    }
    #endif

    var skColor: SKColor {
        #if os(macOS)
        // On macOS the `SKColor(named:)` works, but doesn't like sRGB colors, which causes the app to crash. The colors have to be converted to `deviceRGB` colorspace.
        return self.nsColor
        #else
        return SKColor(named: self.rawValue) ?? SKColor.red
        #endif
    }
}
