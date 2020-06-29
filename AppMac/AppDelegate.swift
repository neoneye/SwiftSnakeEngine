// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SwiftUI
import EngineMac

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var player1Menu: PlayerMenu!
	@IBOutlet weak var player2Menu: PlayerMenu!

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

        if case .develop_runDatasetCompiler(let version) = AppConstant.mode {
            switch version {
            case 1:
                DatasetCompiler1.run()
            case 2:
                DatasetCompiler2.run()
            default:
                ()
            }
            NSApp.terminate(self)
            return;
        }

        window = GameNSWindow.create()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
