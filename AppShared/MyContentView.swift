// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import Combine

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct MyContentView: View {
    @ObservedObject var model: MyModel

    @State private var player1Dead: Bool = false
    @State private var player2Dead: Bool = false
    @State var presentingModal = false
    var isPreview: Bool = false
    let player1ColorAlive: Color = AppColor.player1_snakeBody.color
    let player2ColorAlive: Color = AppColor.player2_snakeBody.color

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
                let length: UInt = self.model.player1Length
                self.model.player1Length = length + 1
            }
            Button("-") {
                let length: UInt = self.model.player1Length
                if length >= 1 {
                    self.model.player1Length = length - 1
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
                let length: UInt = self.model.player2Length
                self.model.player2Length = length + 1
            }
            Button("-") {
                let length: UInt = self.model.player2Length
                if length >= 1 {
                    self.model.player2Length = length - 1
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

                Text(model.player1Info)
                    .padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(self.player1Color)
                    .foregroundColor(.black)

                if self.showDebugPanels {
                    debugPanel1
                }

            }

            if model.player1Length >= 1 {
                PlayerScoreView(
                    playerLength: $model.player1Length,
                    color: self.player1Color
                )
            }
        }
    }

    var rightSide: some View {
        HStack(spacing: 1) {
            if model.player2Length >= 1 {
                PlayerScoreView(
                    playerLength: $model.player2Length,
                    color: self.player2Color
                )
            }

            VStack(alignment: .leading, spacing: 0) {

                Text(model.player2Info)
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
        if model.player1Length >= 1 {
            return 1
        } else {
            return 0
        }
    }

    var rightSideOpacity: Double {
        if model.player2Length >= 1 {
            return 1
        } else {
            return 0
        }
    }

    private var spriteKitContainer: SpriteKitContainer {
        SpriteKitContainer(
            model: self.model,
            isPreview: self.isPreview
        )
    }

    private var pauseButton: some View {
        Button(action: {
            log.debug("pause button pressed")
            self.presentingModal = true
        }) {
            Image("PauseButton")
                .scaleEffect(0.6)
                .padding(15)
        }
        .sheet(isPresented: $presentingModal) {
            PauseSheetView(model: self.model, presentedAsModal: self.$presentingModal)
        }
    }

    private var iOS_overlayWithPauseButton: some View {
        VStack {
            HStack {
                pauseButton
                Spacer()
            }
            Spacer()
        }
    }

    private var iOS_overlayWithHeader_inner: some View {
        return VStack {
            HStack {
                Text("Battle the AI")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Toggle("Battle the AI", isOn: $model.levelSelector_humanVsBot)
                .labelsHidden()
            }
            .padding(EdgeInsets(top: 30, leading: 30, bottom: 10, trailing: 30))

        }
        .frame(minWidth: 80, maxWidth: .infinity)
        .modifier(ViewHeightGetter())
        .onPreferenceChange(ViewHeightPreferenceKey.self) { [weak model] (viewHeight: CGFloat) in
            log.debug("height of view: \(viewHeight)")
            model?.levelSelector_insetTop = viewHeight
        }
        .background(Color.white.opacity(0.5))
    }

    private var iOS_overlayWithHeader: some View {
        return VStack {
            iOS_overlayWithHeader_inner

            Spacer()
        }
        .foregroundColor(Color.black)
    }

    private var macOS_footer: some View {
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

    var macOS_body: some View {
        VStack(spacing: 1) {
            spriteKitContainer

            macOS_footer
        }
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: isPreview ? 100 : 400, maxWidth: .infinity, minHeight: isPreview ? 80 : 400, maxHeight: .infinity)
    }

    var iOS_body: some View {
        ZStack {
            spriteKitContainer

            if model.showPauseButton {
                iOS_overlayWithPauseButton
            }

            if model.levelSelector_visible {
                iOS_overlayWithHeader
            }
        }
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: isPreview ? 100 : 400, maxWidth: .infinity, minHeight: isPreview ? 80 : 400, maxHeight: .infinity)
    }

    var body: some View {
        #if os(macOS)
        return macOS_body
        #else
        return iOS_body
        #endif
    }

}

struct ContentView_Previews : PreviewProvider {

    static var previews: some View {
        let model = MyModel()
        return Group {
            MyContentView(model: model, isPreview: true)
                .previewLayout(.fixed(width: 130, height: 200))
            MyContentView(model: model, isPreview: true)
                .previewLayout(.fixed(width: 300, height: 200))
            MyContentView(model: model, isPreview: true)
                .previewLayout(.fixed(width: 500, height: 150))
        }
    }

}
