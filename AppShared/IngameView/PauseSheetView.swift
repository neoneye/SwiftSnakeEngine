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
            Text("Sound")
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

    private var replayView: some View {
        guard let model: IngameViewModel = self.model.replayGameViewModel else {
            log.error("There is replay data to be replayed")
            return AnyView(EmptyView())
        }
        log.debug("Greated gameviewmodel with the replay data")
        let view = IngameView(
            model: model,
            mode: .replayOnPauseSheet
        )
        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
        return AnyView(view)
    }

    private var continueGameButton: some View {
        Button("Continue Game") {
            self.presentedAsModal = false
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

    var bodyWithoutNavigationBar: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            macOS_navigationBar
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

            if AppConstant.develop_showReplayOnPauseSheet {
                // Show replay of the game
                replayView
            }

            exitGameButton
                .padding(.top, 10)
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
        model.replayGameViewModel = model
        return PauseSheetView(model: model, presentedAsModal: .constant(true))
            .environmentObject(settingStore)
            .previewLayout(.fixed(width: 400, height: 500))
    }
}
