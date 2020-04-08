// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SpriteKit
import EngineMac

extension SKScene {
	func snake_becomeFirstResponder() {
		guard let window: NSWindow = self.view?.window else {
			// This scene is not installed in a window. Cannot make the scene first responder.
			log.error("snake_becomeFirstResponder() Expected the scene to be installed in a window, but it's not.")
			return
		}
		let responder: NSResponder? = window.firstResponder
		if responder === self {
			// This scene is already the first responder
			return
		}
		//log.debug("making this scene the first responder")
		let ok: Bool = window.makeFirstResponder(self)
		guard ok else {
			log.error("snake_becomeFirstResponder() Expected NSWindow.makeFirstResponder() to return true, but got false.")
			return
		}
		//log.debug("makeFirstResponder success")
	}
}
