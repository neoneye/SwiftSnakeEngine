// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

struct RootView: View {
    @State var model: GameViewModel
    @ObservedObject var levelSelectorViewModel: LevelSelectorViewModel
    @ObservedObject var settingStore: SettingStore

    var body: some View {
        MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, visibleContent: .levelSelector)
        .environmentObject(settingStore)
    }
}
