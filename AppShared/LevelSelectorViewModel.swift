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


public class LevelSelectorViewModel: ObservableObject {
    @Published var models: [GameViewModel] = []

    var cancellables = Set<AnyCancellable>()

    init() {
        let settingsUpdated = Notification.Name("SettingsUpdated")
        NotificationCenter.default.publisher(for: settingsUpdated)
            .sink(receiveValue: { _ in
                log.debug("settings updated")
            })
            .store(in: &cancellables)
    }

    func useMockData() {
        let model = GameViewModel.create()
        models = Array<GameViewModel>(repeating: model, count: 9)
    }

    func loadModelsFromUserDefaults() {
        let gameStates: [SnakeGameState] = LevelSelectorDataSource.createGameStatesWithUserDefaults()
        models = gameStates.toGameViewModels()
    }
}
