// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import SSEventFlow

class GameNSView<Content>: NSHostingView<Content> where Content : View {
    required init(rootView: Content) {
        super.init(rootView: rootView)
        setupTrackingArea()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Workaround: In order to show tooltips while the ingame UI is shown.
    ///
    /// The `SKScene.mouseMoved()` function doesn't get invoked. I suspect it has to do with I'm using SwiftUI.
    /// So I'm now listening for events inside the `NSTrackingArea`.
    func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .activeInKeyWindow, .inVisibleRect]
        self.addTrackingArea(NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        FlowEvent_GameNSView_MouseMoved(nsEvent: event).fire()
    }
}

class FlowEvent_GameNSView_MouseMoved: FlowEvent {
    let nsEvent: NSEvent
    init(nsEvent: NSEvent) {
        self.nsEvent = nsEvent
    }
}
