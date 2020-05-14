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
        if AppConstant.useSwiftUIInsteadOfSpriteKit {
            publisher.send(event)
        } else {
            super.keyDown(with: event)
        }
    }

    static func create() -> GameNSWindow {
        let settingStore = SettingStore()

        let levelSelectorViewModel = LevelSelectorViewModel()
        levelSelectorViewModel.loadModelsFromUserDefaults()
        levelSelectorViewModel.selectedIndex = settingStore.selectedLevel

        let model = GameViewModel.create()
//        let model = GameViewModel.createBotVsNone()
//        let model = GameViewModel.createBotVsBot()
//        let model = GameViewModel.createHumanVsBot()
        let window = GameNSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        let view = MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, settingStore: settingStore)
            .environment(\.keyPublisher, window.keyEventPublisher)
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
