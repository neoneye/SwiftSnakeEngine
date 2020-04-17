// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
public protocol FlowEvent {}

extension FlowEvent {
	/// Send event to all installed dispatchers
	public func fire() { FlowManager.shared.dispatch(self) }
}

public protocol FlowDispatcher: class {
	func flow_dispatch(_ event: FlowEvent)
}

extension FlowDispatcher {
	/// Start listening for events. Does nothing if already started.
	public func flow_start() { FlowManager.shared.install(self) }

	/// Stop listening for events. Does nothing if already stopped.
	public func flow_stop() { FlowManager.shared.uninstall(self) }
}

internal class FlowManager {
	static var shared = FlowManager()

	struct Box {
		weak var dispatcher: FlowDispatcher?
	}
	var boxes = [Box]()

	func dispatch(_ event: FlowEvent) {
		purge()
		for box in boxes { box.dispatcher?.flow_dispatch(event) }
	}

	func purge() {
		boxes = boxes.filter { $0.dispatcher != nil }
	}

	func reset() {
		boxes = []
	}

	func install(_ dispatcher: FlowDispatcher) {
		uninstall(dispatcher)
		boxes.append(Box(dispatcher: dispatcher))
	}

	func uninstall(_ dispatcher: FlowDispatcher) {
		boxes = boxes.filter { $0.dispatcher !== dispatcher }
		purge()
	}
}
