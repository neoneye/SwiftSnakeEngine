// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit
import Combine
import SwiftUI

#if os(iOS)
import UIKit
import EngineIOS
#elseif os(macOS)
import Cocoa
import EngineMac
#else
#error("Unknown OS")
#endif


#if os(iOS)
typealias ViewRepresentableType = UIViewRepresentable
#elseif os(macOS)
typealias ViewRepresentableType = NSViewRepresentable
#else
#error("Unknown OS")
#endif



struct SpriteKitContainer: ViewRepresentableType {
    @ObservedObject var model: MyModel
    @Binding var player1Info: String
    @Binding var player2Info: String
	var isPreview: Bool = false

    class Coordinator: NSObject {
        var cancellable = Set<AnyCancellable>()
        var parent: SpriteKitContainer

        init(_ parent: SpriteKitContainer) {
            self.parent = parent
        }

        func sendInfoEvent(_ event: SnakeGameInfoEvent) {
            switch event {
            case .showLevelSelector:
                if !parent.isPreview {
                    parent.player1Info = ""
                    parent.player2Info = ""
                }
            case let .showLevelDetail(gameState):
                parent.player1Info = gameState.player1.humanReadableRole
                parent.player2Info = gameState.player2.humanReadableRole
            case let .beginNewGame(gameState):
                parent.player1Info = gameState.player1.humanReadableRole
                parent.player2Info = gameState.player2.humanReadableRole
            case let .player1_didUpdateLength(length):
                ()
            case let .player2_didUpdateLength(length):
                ()
            case let .player1_killed(killEvents):
                let deathExplanations: [String] = killEvents.map { $0.humanReadableDeathExplanation }
                let info: String = deathExplanations.joined(separator: "\n-\n")
                parent.player1Info = info
            case let .player2_killed(killEvents):
                let deathExplanations: [String] = killEvents.map { $0.humanReadableDeathExplanation }
                let info: String = deathExplanations.joined(separator: "\n-\n")
                parent.player2Info = info
            }
        }
    }

	func makeCoordinator() -> Coordinator {
		return Coordinator(self)
	}

	func inner_makeView(context: Context) -> SnakeGameSKView {
		SnakeLevelManager.setup()
		let view = SnakeGameSKView(frame: .zero)
        view.onSendInfoEvent = { [weak model] (event: SnakeGameInfoEvent) in
            model?.sendInfoEvent(event)
            context.coordinator.sendInfoEvent(event)
        }
		if isPreview {
			view.preferredFramesPerSecond = 1
		} else {
			view.preferredFramesPerSecond = 60
		}

        if AppConstant.SpriteKit.showDeveloperInfo {
            view.showsFPS = true
            view.showsNodeCount = true
        }

		view.ignoresSiblingOrder = true

		let scene: SKScene
		switch AppConstant.mode {
		case .production:
			scene = SnakeLevelSelectorScene.create()
		case .develop_humanVsNone:
			scene = SnakeGameScene.createHumanVsNone()
        case .develop_botVsNone:
            scene = SnakeGameScene.createBotVsNone()
		}
		view.presentScene(scene)

        // The user is currently in a game with the pause screen shown.
        // The user now chooses to exit the game and jump to the level selector.
        model.jumpToLevelSelector
            .sink { [weak view] in
                log.debug("jumpToLevelSelector")
                view?.scene?.transitionToLevelSelectorScene()
            }
            .store(in: &context.coordinator.cancellable)

		return view
	}

    #if os(iOS)
    func makeUIView(context: Context) -> SnakeGameSKView {
        return inner_makeView(context: context)
    }
    #elseif os(macOS)
    func makeNSView(context: Context) -> SnakeGameSKView {
        return inner_makeView(context: context)
    }
    #endif

    #if os(iOS)
    static func dismantleUIView(_ uiView: SnakeGameSKView, coordinator: Coordinator) {
        log.debug("cancellable.removeAll")
        coordinator.cancellable.removeAll()
    }
    #elseif os(macOS)
    static func dismantleNSView(_ nsView: SnakeGameSKView, coordinator: Coordinator) {
        log.debug("cancellable.removeAll")
        coordinator.cancellable.removeAll()
    }
    #endif


    #if os(iOS)
    func updateUIView(_ uiView: SnakeGameSKView, context: Context) {
    }
    #elseif os(macOS)
    func updateNSView(_ view: SnakeGameSKView, context: Context) {
    }
    #endif
}

struct SpriteKitContainer_Previews : PreviewProvider {

	static var previews: some View {
        let model = MyModel()
        return Group {
            SpriteKitContainer(model: model, player1Info: .constant("TEST"), player2Info: .constant("TEST"), isPreview: true).previewLayout(.fixed(width: 125, height: 200))
			SpriteKitContainer(model: model, player1Info: .constant("TEST"), player2Info: .constant("TEST"), isPreview: true).previewLayout(.fixed(width: 150, height: 150))
            SpriteKitContainer(model: model, player1Info: .constant("TEST"), player2Info: .constant("TEST"), isPreview: true).previewLayout(.fixed(width: 200, height: 125))
		}
	}

}
