// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import EngineMac

class GameNSWindow: NSWindow {
    static func create() -> GameNSWindow {
        let window = GameNSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = GameNSView.create()
        window.makeKeyAndOrderFront(nil)
        return window
    }
}
