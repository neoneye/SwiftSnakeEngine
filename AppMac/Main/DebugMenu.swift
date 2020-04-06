// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SnakeGame
import SSEventFlow

class FlowEvent_PerformUndo: FlowEvent {}

class FlowEvent_PerformRedo: FlowEvent {}

class DebugMenu: NSMenu {
	@IBAction func undoAction(_ sender: NSMenuItem) {
		FlowEvent_PerformUndo().fire()
	}

	@IBAction func redoAction(_ sender: NSMenuItem) {
        log.debug("User pressed F6 key")
		FlowEvent_PerformRedo().fire()
	}
}
