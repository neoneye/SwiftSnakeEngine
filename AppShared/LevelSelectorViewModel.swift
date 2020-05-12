// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import Combine
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

enum LevelSelectorViewModel_VisibleContent {
    case levelSelector
    case ingame
}

public class LevelSelectorViewModel: ObservableObject {
    @Published var visibleContent = LevelSelectorViewModel_VisibleContent.levelSelector

}
