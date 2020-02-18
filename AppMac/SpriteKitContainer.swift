// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SpriteKit
import SwiftUI
import SnakeGame

struct SpriteKitContainer: NSViewRepresentable {
	var isPreview: Bool = false

	class Coordinator: NSObject {
	}

	func makeCoordinator() -> Coordinator {
		return Coordinator()
	}

	func makeNSView(context: Context) -> SKView {
		SnakeLevelManager.setup()
		let view = SKView(frame: .zero)
		if isPreview {
			view.preferredFramesPerSecond = 1
		} else {
			view.preferredFramesPerSecond = 60
		}
		view.showsFPS = true
		view.showsNodeCount = true
		view.ignoresSiblingOrder = true

		let scene: SKScene
		switch AppConstant.mode {
		case .production:
			scene = SnakeLevelSelectorScene.create()
		case .experimentWithAI:
			scene = SnakeGameScene.createBotsVsBots()
		}
		view.presentScene(scene)
		return view
	}


	func updateNSView(_ view: SKView, context: Context) {
	}
}

struct SpriteKitContainer_Previews : PreviewProvider {

	static var previews: some View {
		Group {
            SpriteKitContainer(isPreview: true).previewLayout(.fixed(width: 125, height: 200))
			SpriteKitContainer(isPreview: true).previewLayout(.fixed(width: 150, height: 150))
			SpriteKitContainer(isPreview: true).previewLayout(.fixed(width: 200, height: 125))
		}
	}

}
