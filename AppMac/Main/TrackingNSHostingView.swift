// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import SSEventFlow

/// This is a workaround.
///
/// The `SKScene.mouseMoved()` function doesn't get invoked. I suspect it has to do with I'm using SwiftUI.
/// So I'm now listening for events inside the `NSTrackingArea`.
class TrackingNSHostingView<Content>: NSHostingView<Content> where Content : View {
    required init(rootView: Content) {
        super.init(rootView: rootView)
        setupTrackingArea()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .activeInKeyWindow, .inVisibleRect]
        self.addTrackingArea(NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        FlowEvent_TrackingNSHostingView_MouseMoved(nsEvent: event).fire()
    }
}

class FlowEvent_TrackingNSHostingView_MouseMoved: FlowEvent {
    let nsEvent: NSEvent
    init(nsEvent: NSEvent) {
        self.nsEvent = nsEvent
    }
}
