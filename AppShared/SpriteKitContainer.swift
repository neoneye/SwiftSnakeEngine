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
    @ObservedObject var model: GameViewModel
	var isPreview: Bool = false

    class Coordinator {
        var cancellable = Set<AnyCancellable>()
    }

	func makeCoordinator() -> Coordinator {
		return Coordinator()
	}

	func inner_makeView(context: Context) -> SnakeGameSKView {
		SnakeLevelManager.setup()
		let view = SnakeGameSKView(model: model)
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

        // Used while the user is ingame with the pause screen shown.
        // Here the user can choose to exit the game and jump to the level selector.
        model.jumpToLevelSelector
            .sink { [weak view, weak model] in
                log.debug("jumpToLevelSelector")
                model?.showPauseButton = false
                view?.scene?.transitionToLevelSelectorScene()
            }
            .store(in: &context.coordinator.cancellable)

		let scene: SKScene
        let showPauseButton: Bool
		switch AppConstant.mode {
		case .production:
            scene = LevelSelectorScene()
            showPauseButton = false
		case .develop_humanVsNone:
            scene = IngameScene.createHumanVsNone()
            showPauseButton = true
        case .develop_botVsNone:
            scene = IngameScene.createBotVsNone()
            showPauseButton = true
        case .develop_replay:
            scene = IngameScene.createReplay()
            showPauseButton = true
		}
		view.presentScene(scene)
        model.showPauseButton = showPauseButton

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
        let model = GameViewModel.create()
        return Group {
            SpriteKitContainer(model: model, isPreview: true).previewLayout(.fixed(width: 125, height: 200))
			SpriteKitContainer(model: model, isPreview: true).previewLayout(.fixed(width: 150, height: 150))
            SpriteKitContainer(model: model, isPreview: true).previewLayout(.fixed(width: 200, height: 125))
		}
	}

}
