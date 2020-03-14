// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SSEventFlow

class FlowEvent_PerformUndo: FlowEvent {}

class FlowEvent_PerformRedo: FlowEvent {}

class DebugMenu: NSMenu {
	@IBAction func undoAction(_ sender: NSMenuItem) {
		FlowEvent_PerformUndo().fire()
	}

	@IBAction func redoAction(_ sender: NSMenuItem) {
		FlowEvent_PerformRedo().fire()
	}
}
