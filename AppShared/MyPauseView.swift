// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct MyPauseView: View {
    @Binding var presentedAsModal: Bool
    @State var showExitGameAlert = false

    var exitGameAlert: Alert {
        return Alert(
            title: Text("Do you want to exit game?"),
            message: Text("This will delete your current snake game progress."),
            primaryButton: Alert.Button.destructive(Text("Exit game"), action: {
                log.debug("Exit game. Yes, I'm sure!")
            }),
            secondaryButton: Alert.Button.cancel()
        )
    }

    var exitGameButton: some View {
        return Button(action: {
            log.debug("show exit game alert")
            self.showExitGameAlert.toggle()
        }) {
            Text("Exit Game")
                .foregroundColor(.white)
                .padding(.all)
        }
        .background(Color.red)
        .cornerRadius(5)
        .alert(isPresented: $showExitGameAlert, content: {
            exitGameAlert
        })
    }

    #if os(iOS)

    var contentArea: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                Text("Human\nLength 14")
                Text("Computer\nLength 18")
            }

            Spacer()

            exitGameButton
        }
        .padding(EdgeInsets(top: 40, leading: 0, bottom: 40, trailing: 0))
    }

    var body: some View {
        NavigationView {
            contentArea
                .navigationBarTitle("Game Paused")
                .navigationBarItems(leading:
                    Button("Continue") { self.presentedAsModal = false }
                )
        }
    }
    #else
    var body: some View {
        Button("Continue") { self.presentedAsModal = false }
    }
    #endif
}

struct MyPauseView_Previews: PreviewProvider {
    static var previews: some View {
        MyPauseView(presentedAsModal: .constant(true))
    }
}
