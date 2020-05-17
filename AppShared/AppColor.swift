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

enum AppColor: String, CaseIterable {
    case levelSelector_background
    case levelSelector_border
    case ingame_background
    case ingame_pauseButton
    case player1_plannedPath
    case player2_plannedPath
    case player1_snakeBody
    case player2_snakeBody
    case player1_snakeBody_dead
    case player2_snakeBody_dead
    case exitGameButton_fill
    case exitGameButton_text
    case theme1_wall
    case theme1_food
    case theme1_floor
    case theme2_floor
}

extension AppColor {
    var color: Color {
        return Color(self.rawValue)
    }

    var skColor: SKColor {
        #if os(macOS)
        return AppColorManager.shared.nsColor(self) ?? NSColor.red
        #else
        return SKColor(named: self.rawValue) ?? SKColor.red
        #endif
    }
}


#if os(macOS)
/// Ideally I want to use `SKColor(named:)` for both macOS and iOS.
/// However on macOS the `SKColor(named:)` compiles fine, but doesn't behave correct.
/// So I'm using `NSColor` instead of `SKColor`.
///
/// ---
///
/// The iOS app has no problems with `sRGB`.
/// PROBLEM: The macOS app crashes if there is a color in xcassets that uses the `sRGB` colorspace.
/// SOLUTION: Convert to `colorSpace(.deviceRGB)`.
///
/// ---
///
/// In the iOS app the `SKColor(named:)` always reflect the current appearance settings.
/// PROBLEM: Whenever the macOS appearance Light/Dark changes,
/// then the `NSColor(named:)` briefly yields the color with the current appearance.
/// After a few seconds the color is switched back to the original appearance when the app was launched.
/// SOLUTION: Syncronize all the colors inside `viewDidChangeEffectiveAppearance()`.
///
/// The Apple documentation mentions that the color refreshing must take place inside `updateLayer()`.
/// https://developer.apple.com/documentation/xcode/supporting_dark_mode_in_your_interface
class AppColorManager {
    static let shared = AppColorManager()

    private var dict: [AppColor: NSColor] = [:]

    private init() {
        resolveNSColors()
    }

    func nsColor(_ appColor: AppColor) -> NSColor? {
        return dict[appColor]
    }

    /// Called whenever there are changes to Light/Dark appearance
    func resolveNSColors() {
        for appColor in AppColor.allCases {
            dict[appColor] = resolveNSColor(named: appColor.rawValue)
        }
    }

    private func resolveNSColor(named name: String) -> NSColor {
        guard let color0 = NSColor(named: name) else {
            log.error("Cannot find color in xcassets. \(name)")
            return NSColor.red
        }
        guard let color1: NSColor = color0.usingColorSpace(.deviceRGB) else {
            log.error("Cannot convert color to rgb colorspace. \(name)")
            return NSColor.red
        }
        return color1
    }
}

#endif
