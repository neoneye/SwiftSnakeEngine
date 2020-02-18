// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SpriteKit
import SwiftUI
import SnakeGame

class MyHostingController: NSHostingController<MyContentView> {
	@objc required dynamic init?(coder: NSCoder) {
		super.init(coder: coder, rootView: MyContentView())
	}
}

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

struct MyContentView: View {
	var isPreview: Bool = false

    var body: some View {
        VStack(spacing: 1) {
			SpriteKitContainer(isPreview: isPreview)
            HStack(spacing: 1) {
				Text("Player 1 (green)\nAlive\nLength 29")
					.padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.green)
				Text("Player 2 (blue)\nDead by collision with wall\nLength 14")
					.padding(10)
.frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.blue)
			}
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 80, maxHeight: 100)
		}
        .edgesIgnoringSafeArea(.all)
	}
}

struct ContentView_Previews : PreviewProvider {

	static var previews: some View {
		Group {
            MyContentView(isPreview: true).previewLayout(.fixed(width: 130, height: 200))
			MyContentView(isPreview: true).previewLayout(.fixed(width: 300, height: 200))
			MyContentView(isPreview: true).previewLayout(.fixed(width: 400, height: 150))
		}
	}

}
