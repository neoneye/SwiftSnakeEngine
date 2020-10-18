// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import Combine
import SwiftUI
import EngineMac

class GameNSWindow: NSWindow {
    private let publisher = PassthroughSubject<NSEvent, Never>()

    var keyEventPublisher: AnyPublisher<NSEvent, Never> {
        publisher.eraseToAnyPublisher()
    }

    override func keyDown(with event: NSEvent) {
        publisher.send(event)
    }

    static func create() -> GameNSWindow {
        let settingStore = SettingStore()

        let levelSelectorViewModel = LevelSelectorViewModel()
        levelSelectorViewModel.loadModelsFromUserDefaults()
        levelSelectorViewModel.selectedIndex = settingStore.selectedLevel

        let visibleContent: MyContentView_VisibleContent
        let model: IngameViewModel
        switch AppConstant.mode {
        case .production:
            visibleContent = .levelSelector
            model = IngameViewModel.createBotVsNone().toInteractiveModel()
        case .develop_ingame:
            visibleContent = .ingame
            model = IngameViewModel.create()
        case .develop_replay(let resourceName):
            visibleContent = .ingame
            model = IngameViewModel.createReplay(resourceName: resourceName)
        case .develop_runDatasetCompiler:
            fatalError()
        }

        let window = GameNSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        let view = MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, visibleContent: visibleContent)
            .environment(\.keyPublisher, window.keyEventPublisher)
            .environmentObject(settingStore)
        window.contentView = GameNSView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        return window
    }
}

// Environment key to hold even publisher
struct WindowEventPublisherKey: EnvironmentKey {
    static let defaultValue: AnyPublisher<NSEvent, Never> =
        Just(NSEvent()).eraseToAnyPublisher()
}


// Environment value for keyPublisher access
extension EnvironmentValues {
    var keyPublisher: AnyPublisher<NSEvent, Never> {
        get { self[WindowEventPublisherKey.self] }
        set { self[WindowEventPublisherKey.self] = newValue }
    }
}
