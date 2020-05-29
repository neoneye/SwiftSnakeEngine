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
    @ObservedObject var model: GameViewModel
    @Binding var presentedAsModal: Bool
    @State var showExitGameAlert = false

    var exitGameAlert: Alert {
        return Alert(
            title: Text("Do you want to exit game?"),
            message: Text("This will delete your current snake game progress."),
            primaryButton: Alert.Button.destructive(Text("Exit game"), action: {
                log.debug("Exit game. Yes, I'm sure!")
                self.presentedAsModal = false
                self.model.jumpToLevelSelector.send()
            }),
            secondaryButton: Alert.Button.cancel()
        )
    }

    var soundEffectsButton: some View {
        return HStack {
            Text("Sound effects")
            Toggle("Sound effects", isOn: self.$settingStore.isSoundEffectsEnabled).labelsHidden()
        }
    }

    var exitGameButton: some View {
        return Button(action: {
            log.debug("show exit game alert")
            self.showExitGameAlert.toggle()
        }) {
            Text("Exit Game")
                .foregroundColor(AppColor.exitGameButton_text.color)
                .padding(.all)
        }
        .buttonStyle(BorderlessButtonStyle())
        .background(AppColor.exitGameButton_fill.color)
        .cornerRadius(5)
        .alert(isPresented: $showExitGameAlert, content: {
            exitGameAlert
        })
    }

    private var ingameView: some View {
        guard let model: GameViewModel = self.model.createReplay() else {
            log.error("Unable to do a replay of the current model")
            return AnyView(EmptyView())
        }
        log.debug("created gameviewmodel with the replay")
        let view = IngameView(
            model: model,
            mode: .replayOnPauseSheet
        )
        .frame(width: 200, height: 200)
        return AnyView(view)
    }

    var bodyWithoutNavigationBar: some View {
        VStack(spacing: 20) {
            #if os(macOS)
            Button("Continue Game") {
                self.presentedAsModal = false
                self.model.pauseSheet_dismissSheetAndContinueGame()
            }
            #endif

            HStack(alignment: .top) {
                Text(self.model.player1Summary)
                .foregroundColor(Color.black)
                .padding()
                .background(AppColor.player1_snakeBody.color)

                Spacer()

                Text(self.model.player2Summary)
                .foregroundColor(Color.black)
                .padding()
                .background(AppColor.player2_snakeBody.color)
            }

            Spacer()

            if AppConstant.develop_showReplayOnPauseSheet {
                // Show replay of the game
                ingameView
                Spacer()
            }

            soundEffectsButton

            Spacer()

            exitGameButton
        }
        .padding(EdgeInsets(top: 40, leading: 0, bottom: 40, trailing: 0))
    }

    #if os(iOS)
    var body: some View {
        NavigationView {
            bodyWithoutNavigationBar
                .navigationBarTitle("Game Paused")
                .navigationBarItems(leading:
                    Button("Continue Game") {
                        self.presentedAsModal = false
                        self.model.pauseSheet_dismissSheetAndContinueGame()
                    }
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
        let model = GameViewModel.create()
        return PauseSheetView(model: model, presentedAsModal: .constant(true))
            .environmentObject(settingStore)
            .previewLayout(.fixed(width: 400, height: 500))
    }
}
