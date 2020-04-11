// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

struct MyPauseView: View {
    @Binding var presentedAsModal: Bool

    #if os(iOS)
    var body: some View {
        NavigationView {
            Text("Content")
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
