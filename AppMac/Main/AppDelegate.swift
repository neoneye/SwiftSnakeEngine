// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SwiftUI
import SnakeGame

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var player1Menu: PlayerMenu!
	@IBOutlet weak var player2Menu: PlayerMenu!
	@IBOutlet weak var debugMenu: DebugMenu!

    var window: NSWindow!

	override init() {
		super.init()
        LogHelper.setup_mainExecutable()
        Dashboard.shared.url = AppConstant.Dashboard.url
		SnakeLevelManager.setup()
	}

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        player1Menu?.configureAsPlayer1()
		player2Menu?.configureAsPlayer2()

//		let game = SnakeGameHeadless()
//		game.run()

        let contentView = MyContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
