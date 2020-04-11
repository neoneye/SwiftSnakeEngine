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

    #if os(iOS)

    var contentArea: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                Text("Human\nLength 14")
                Text("Computer\nLength 18")
            }

            Spacer()

            Button(action: {
                log.debug("exit")
            }) {
                Text("Exit Game")
                    .foregroundColor(.white)
                    .padding(.all)
            }
            .background(Color.red)
            .cornerRadius(5)
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
