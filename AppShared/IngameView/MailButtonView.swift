// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import MessageUI

struct MailButtonView: View {
    let dataset_mailAttachmentData: Data
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView = false

    var body: some View {
        Button(action: {
            self.isShowingMailView.toggle()
        }) {
            Text("Tap Me")
        }
        .disabled(!MFMailComposeViewController.canSendMail())
        .sheet(isPresented: $isShowingMailView) {
            MailView(
                result: self.$result,
                dataset_mailAttachmentData: self.dataset_mailAttachmentData
            )
        }
    }
}

struct MailButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MailButtonView(
            dataset_mailAttachmentData: Data()
        )
    }
}
