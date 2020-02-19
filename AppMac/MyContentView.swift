// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SpriteKit
import SwiftUI
import SnakeGame
import Combine

class MyHostingController: NSHostingController<MyContentView> {
    @objc required dynamic init?(coder: NSCoder) {
        super.init(coder: coder, rootView: MyContentView())
    }
}

struct MyContentView: View {
    @State private var player1Length: UInt = 1
    @State private var player2Length: UInt = 2
    @State private var player1Info = "Player 1 (green)\nAlive\nLength 29"
    @State private var player2Info = "Player 2 (blue)\nDead by collision with wall\nLength 14"
    var isPreview: Bool = false

    var body: some View {
        VStack(spacing: 1) {
            SpriteKitContainer(player1Length: $player1Length, player2Length: $player2Length, player1Info: $player1Info, player2Info: $player2Info, isPreview: isPreview)
            HStack(spacing: 1) {

                Text(player1Info)
                    .padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.green.saturation(0.7))

                PlayerScoreView(playerLength: $player1Length)

                PlayerScoreView(playerLength: $player2Length)

                Text(player2Info)
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
        Group {
            MyContentView(isPreview: true)
                .previewLayout(.fixed(width: 130, height: 200))
            MyContentView(isPreview: true)
                .previewLayout(.fixed(width: 300, height: 200))
            MyContentView(isPreview: true)
                .previewLayout(.fixed(width: 400, height: 150))
        }
    }

}
