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
    let player1Color: Color = .green
    let player2Color: Color = .blue

    var body: some View {
        VStack(spacing: 1) {
            
            SpriteKitContainer(
                player1Length: self.$player1Length,
                player2Length: self.$player2Length,
                player1Info: self.$player1Info,
                player2Info: self.$player2Info,
                isPreview: self.isPreview
            )

            HStack(spacing: 1) {

                HStack(spacing: 1) {
                    Text(player1Info)
                        .padding(10)
                        .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                        .background(self.player1Color)
                        .foregroundColor(.black)

                    if self.$player1Length.wrappedValue >= 1 {
                        PlayerScoreView(
                            playerLength: self.$player1Length,
                            color: self.player1Color
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 1) {

                    if self.$player2Length.wrappedValue >= 1 {
                        PlayerScoreView(
                            playerLength: self.$player2Length,
                            color: self.player2Color
                        )
                    }

                    Text(player2Info)
                        .padding(10)
                        .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                        .background(self.player2Color)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
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
                .previewLayout(.fixed(width: 500, height: 150))
        }
    }

}
