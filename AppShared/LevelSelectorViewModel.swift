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
    let gridSize = UIntVec2(x: 3, y: 3)

    @Published var models: [GameViewModel] = []
    @Published var selectedIndex: UInt = 3

    private var cancellables = Set<AnyCancellable>()

    private var dataSource: LevelSelectorDataSource?

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
        let newDataSource = LevelSelectorDataSource.createWithUserDefaults()
        guard dataSource != newDataSource else {
            //log.debug("no change to level selector data source")
            return
        }
        dataSource = newDataSource
        let gameStates: [SnakeGameState] = newDataSource.createGameStates()
        models = gameStates.toPreviewGameViewModels()
    }

    func gameViewModelForSelectedIndex() -> GameViewModel? {
        guard Int(selectedIndex) < models.count else {
            return nil
        }
        return models[Int(selectedIndex)]
    }

    // MARK: - Move selection around with arrow keys

    func moveSelectionLeft() {
        let xCellCount = UInt(gridSize.x)
        let selectedIndex: UInt = self.selectedIndex
        let row: UInt = selectedIndex / xCellCount
        let column: UInt = (selectedIndex + xCellCount - 1) % xCellCount
        self.selectedIndex = column + row * xCellCount
    }

    func moveSelectionRight() {
        let xCellCount = UInt(gridSize.x)
        let selectedIndex: UInt = self.selectedIndex
        let row: UInt = selectedIndex / xCellCount
        let column: UInt = (selectedIndex + 1) % xCellCount
        self.selectedIndex = column + row * xCellCount
    }

    func moveSelectionUp() {
        let xCellCount = UInt(gridSize.x)
        let yCellCount = UInt(gridSize.y)
        let selectedIndex: UInt = self.selectedIndex
        let cellCount = xCellCount * yCellCount
        self.selectedIndex = (selectedIndex + cellCount - xCellCount) % cellCount
    }

    func moveSelectionDown() {
        let xCellCount = UInt(gridSize.x)
        let yCellCount = UInt(gridSize.y)
        let selectedIndex: UInt = self.selectedIndex
        let cellCount = xCellCount * yCellCount
        self.selectedIndex = (selectedIndex + xCellCount) % cellCount
    }
}
