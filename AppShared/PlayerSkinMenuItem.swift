// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public enum PlayerSkinMenuItem: String, CaseIterable {
    case retroGreen
    case retroBlue
    case cuteGreen
    case cuteBlue
}

extension PlayerSkinMenuItem {
    public var menuItemTitle: String {
        switch self {
        case .retroGreen:
            return "Retro - Green"
        case .retroBlue:
            return "Retro - Blue"
        case .cuteGreen:
            return "Cute - Green"
        case .cuteBlue:
            return "Cute - Blue"
        }
    }
}
