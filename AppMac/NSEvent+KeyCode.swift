// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import AppKit

enum NSEvent_KeyCodeEnum: UInt16 {
	case letterA = 0
	case letterS = 1
	case letterD = 2
	case letterZ = 6
	case letterW = 13
	case enter = 36
	case tab = 48
	case spacebar = 49
	case escape = 53
	case arrowLeft = 123
	case arrowRight = 124
	case arrowDown = 125
	case arrowUp = 126
}

extension NSEvent {
	var keyCodeEnum: NSEvent_KeyCodeEnum? {
		return NSEvent_KeyCodeEnum(rawValue: self.keyCode)
	}
}
