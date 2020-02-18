// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SpriteKit
import SwiftUI
import SnakeGame
import Combine

class MyHostingController: NSHostingController<MyContentView> {
    @objc required dynamic init?(coder: NSCoder) {
        super.init(coder: coder, rootView: MyContentView(model: MyObservable()))
    }
}

class MyObservable: ObservableObject {
    @Published var player1Info = "Player 1 (green)\nAlive\nLength 29"
    @Published var player2Info = "Player 2 (blue)\nDead by collision with wall\nLength 14"
}

struct MyContentView: View {
    @ObservedObject var model: MyObservable
    var isPreview: Bool = false

    var body: some View {
        VStack(spacing: 1) {
            SpriteKitContainer(isPreview: isPreview)
            HStack(spacing: 1) {
                Text(model.player1Info)
                    .padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.green.saturation(0.7))
                Text(model.player2Info)
                    .padding(10)
.frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.blue.saturation(0.7))
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 80, maxHeight: 100)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews : PreviewProvider {

    static var previews: some View {
        let model = MyObservable()
        return Group {
            MyContentView(model: model, isPreview: true)
                .previewLayout(.fixed(width: 130, height: 200))
            MyContentView(model: model, isPreview: true)
                .previewLayout(.fixed(width: 300, height: 200))
            MyContentView(model: model, isPreview: true)
                .previewLayout(.fixed(width: 400, height: 150))
        }
    }

}
