// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SnakeGame

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var player1Menu: PlayerMenu!
	@IBOutlet weak var player2Menu: PlayerMenu!
	@IBOutlet weak var debugMenu: DebugMenu!

	override init() {
		super.init()
		SnakeLevelManager.setup()
	}

    func applicationDidFinishLaunching(_ aNotification: Notification) {
		player1Menu?.configureAsPlayer1()
		player2Menu?.configureAsPlayer2()

//		let game = SnakeGameHeadless()
//		game.run()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
