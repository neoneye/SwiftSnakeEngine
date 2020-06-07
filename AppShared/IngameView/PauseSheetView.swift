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

struct PauseSheetView: View {
    @EnvironmentObject var settingStore: SettingStore
    @ObservedObject var model: IngameViewModel
    @ObservedObject var replayModel: IngameViewModel
    @Binding var presentedAsModal: Bool
    @State var showExitGameAlert = false

    var soundEffectsButton: some View {
        return HStack {
            Text("Sound")
            Toggle("Sound effects", isOn: self.$settingStore.isSoundEffectsEnabled).labelsHidden()
        }
    }

    func prepareExitGameAlertContent() -> Alert {
        //log.debug("create alert")
        return Alert(
            title: Text("Do you want to exit game?"),
            message: Text("This will delete your current snake game progress."),
            primaryButton: Alert.Button.destructive(Text("Exit game"), action: {
                log.debug("Exit game. Yes, I'm sure!")
                self.presentedAsModal = false
                self.model.pauseSheet_dismissSheetAndExitGame()
            }),
            secondaryButton: Alert.Button.cancel()
        )
    }

    var exitGameButton: some View {
        return Button(action: {
            log.debug("show exit game alert")
            self.replayModel.pauseSheet_stopReplay()
            self.showExitGameAlert.toggle()
        }) {
            Text("Exit Game")
                .foregroundColor(AppColor.exitGameButton_text.color)
                .padding(.all)
        }
        .buttonStyle(BorderlessButtonStyle())
        .background(AppColor.exitGameButton_fill.color)
        .cornerRadius(5)
        .alert(isPresented: $showExitGameAlert, content: prepareExitGameAlertContent)
    }

    var sendDatasetToDeveloperButton: some View {
        #if os(iOS)
        return AnyView(MailButtonView())
        #else
        return AnyView(EmptyView())
        #endif
    }

    /// Shows a replay of the game
    private var replayView: some View {
        let view = IngameView(
            model: replayModel,
            mode: .replayOnPauseSheet
        )
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        return view
    }

    private var continueGameButton: some View {
        Button("Continue Game") {
            self.presentedAsModal = false
            self.replayModel.pauseSheet_stopReplay()
            self.model.pauseSheet_dismissSheetAndContinueGame()
        }
    }

    private var macOS_navigationBar: some View {
        VStack {
            HStack {
                continueGameButton
                Spacer()
                soundEffectsButton
            }

            HStack {
                Text("Game Paused").font(Font.largeTitle)
                Spacer()
            }
        }
        .padding([.top, .leading, .trailing], 10)
    }

    var playerScoreSplitView: some View {
        GeometryReader { geometry in
            self.playerScoreSplitView_inner(geometry)
        }
        .padding([.leading, .trailing], 10)
        .padding(.bottom, 5)
    }

    private func playerScoreSplitView_inner(_ geometry: GeometryProxy) -> some View {
        let size: CGSize = geometry.size
        let spacing: CGFloat = 10
        let width: CGFloat = floor((size.width - spacing) / 2)

        let shadowColorLeft = Color.white.opacity(0.3)
        let shadowColorRight = Color.white.opacity(0.6)

        let leftView = Text(self.model.player1Score)
            .lineLimit(1)
            .font(Font.largeTitle.bold())
            .scaleEffect(1.5)
            .shadow(color: shadowColorLeft, radius: 2, x: 0, y: 0)
            .padding(5)
            .foregroundColor(Color.black)
            .frame(minWidth: width, maxWidth: width, minHeight: 20, maxHeight: .infinity, alignment: .center)
            .background(AppColor.player1_snakeBody.color)

        let rightView = Text(self.model.player2Score)
            .lineLimit(1)
            .font(Font.largeTitle.bold())
            .scaleEffect(1.5)
            .shadow(color: shadowColorRight, radius: 2, x: 0, y: 0)
            .padding(5)
            .foregroundColor(Color.black)
            .frame(minWidth: width, maxWidth: width, minHeight: 20, maxHeight: .infinity, alignment: .center)
            .background(AppColor.player2_snakeBody.color)

        let stackView = HStack(spacing: spacing) {
            leftView
            rightView
        }

        return AnyView(stackView)
    }


    var bodyWithoutNavigationBar: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            macOS_navigationBar
            #endif

            playerScoreSplitView
                .frame(height: 80)

            replayView

            HStack {
                sendDatasetToDeveloperButton
                Spacer()
                exitGameButton
            }
            .padding([.top, .leading, .trailing], 10)
            .padding(.bottom, 20)
        }
    }

    #if os(iOS)
    var body: some View {
        NavigationView {
            bodyWithoutNavigationBar
                .padding(.top, 40)
                .navigationBarTitle("Game Paused")
                .navigationBarItems(
                    leading: continueGameButton,
                    trailing: soundEffectsButton
                )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    #else
    var body: some View {
        bodyWithoutNavigationBar
    }
    #endif
}

struct PauseSheetView_Previews: PreviewProvider {
    static var previews: some View {
        let settingStore = SettingStore()
        let model = IngameViewModel.createHumanVsHuman()
        model.captureReplaySnapshot()
        return PauseSheetView(
            model: model,
            replayModel: model,
            presentedAsModal: .constant(true)
        )
        .environmentObject(settingStore)
        .previewLayout(.fixed(width: 400, height: 500))
    }
}
