// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SwiftUI
import SpriteKit
import Combine
import SnakeGame

struct MyContentView: View {
    @State private var player1Dead: Bool = false
    @State private var player2Dead: Bool = false
    @State private var player1Length: UInt = 1
    @State private var player2Length: UInt = 2
    @State private var player1Info = "Player 1 (green)\nAlive\nLength 29"
    @State private var player2Info = "Player 2 (blue)\nDead by collision with wall\nLength 14"
    var isPreview: Bool = false
    let player1ColorAlive: Color = .green
    let player2ColorAlive: Color = .blue

    let showDebugPanels = false

    var player1Color: Color {
        if player1Dead {
            return player1ColorAlive.opacity(0.3)
        } else {
            return player1ColorAlive
        }
    }

    var player2Color: Color {
        if player2Dead {
            return player2ColorAlive.opacity(0.3)
        } else {
            return player2ColorAlive
        }
    }

    var debugPanel1: some View {
        HStack {
            Button("Dead/Alive") {
                self.player1Dead.toggle()
            }
            Button("+") {
                self.player1Length += 1
            }
            Button("-") {
                let length: UInt = self.player1Length
                if length >= 1 {
                    self.player1Length = length - 1
                }
            }
        }
    }

    var debugPanel2: some View {
        HStack {
            Button("Dead/Alive") {
                self.player2Dead.toggle()
            }
            Button("+") {
                self.player2Length += 1
            }
            Button("-") {
                let length: UInt = self.player2Length
                if length >= 1 {
                    self.player2Length = length - 1
                }
            }
        }
    }

    var stripeImage: some View {
        Image("stripes")
            .resizable(resizingMode: .tile)
            .contrast(0.2)
            .colorMultiply(Color(white: 0.3))
    }

    var leftSide: some View {
        HStack(spacing: 1) {
            VStack(alignment: .leading, spacing: 0) {

                Text(player1Info)
                    .padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(self.player1Color)
                    .foregroundColor(.black)

                if self.showDebugPanels {
                    debugPanel1
                }

            }

            if self.$player1Length.wrappedValue >= 1 {
                PlayerScoreView(
                    playerLength: self.$player1Length,
                    color: self.player1Color
                )
            }
        }
    }

    var rightSide: some View {
        HStack(spacing: 1) {
            if self.$player2Length.wrappedValue >= 1 {
                PlayerScoreView(
                    playerLength: self.$player2Length,
                    color: self.player2Color
                )
            }

            VStack(alignment: .leading, spacing: 0) {

                Text(player2Info)
                    .padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(self.player2Color)
                    .foregroundColor(.black)

                if self.showDebugPanels {
                    debugPanel2
                }
            }
        }
    }

    var leftSideOpacity: Double {
        if self.$player1Length.wrappedValue >= 1 {
            return 1
        } else {
            return 0
        }
    }

    var rightSideOpacity: Double {
        if self.$player2Length.wrappedValue >= 1 {
            return 1
        } else {
            return 0
        }
    }


    var body: some View {
        VStack(spacing: 1) {
            
            SpriteKitContainer(
                player1Length: self.$player1Length,
                player2Length: self.$player2Length,
                player1Info: self.$player1Info,
                player2Info: self.$player2Info,
                isPreview: self.isPreview
            )

            ZStack {
                stripeImage

                HStack(spacing: 1) {

                    leftSide
                        .opacity(leftSideOpacity)
                        .frame(maxWidth: .infinity)

                    rightSide
                        .opacity(rightSideOpacity)
                        .frame(maxWidth: .infinity)

                }

            }
            .frame(minWidth: 80, maxWidth: .infinity, minHeight: 80, maxHeight: 100)
        }
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: isPreview ? 100 : 400, maxWidth: .infinity, minHeight: isPreview ? 80 : 400, maxHeight: .infinity)
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
