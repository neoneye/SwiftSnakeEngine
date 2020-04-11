// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

struct MyPauseView: View {
    @Binding var presentedAsModal: Bool

    var body: some View {
        Button("Continue") { self.presentedAsModal = false }
    }
}

struct MyPauseView_Previews: PreviewProvider {
    static var previews: some View {
        MyPauseView(presentedAsModal: .constant(true))
    }
}
