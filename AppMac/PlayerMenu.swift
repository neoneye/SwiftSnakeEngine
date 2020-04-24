// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SSEventFlow
import EngineMac

class FlowEvent_DidChangePlayerSetting: FlowEvent {}

public enum PlayerMenuMode {
	case player1, player2
}

public protocol PlayerRoleMenuItem {
	var role: SnakePlayerRole { get }
	var userDefaultIdentifier: String { get }
	func menuItemTitle(menuMode: PlayerMenuMode) -> String
}

private class PlayerRoleMenuItemImpl: PlayerRoleMenuItem {
	let role: SnakePlayerRole
	let userDefaultIdentifier: String
	let menuItemTitle: String

	init(role: SnakePlayerRole, userDefaultIdentifier: String, menuItemTitle: String) {
		self.role = role
		self.userDefaultIdentifier = userDefaultIdentifier
		self.menuItemTitle = menuItemTitle
	}

	func menuItemTitle(menuMode: PlayerMenuMode) -> String {
		return self.menuItemTitle
	}
}

private class PlayerRoleMenuItemWithCustomTitleImpl: PlayerRoleMenuItem {
	let role: SnakePlayerRole
	let userDefaultIdentifier: String
	let menuItemTitle_player1: String
	let menuItemTitle_player2: String

	init(role: SnakePlayerRole, userDefaultIdentifier: String, menuItemTitle_player1: String, menuItemTitle_player2: String) {
		self.role = role
		self.userDefaultIdentifier = userDefaultIdentifier
		self.menuItemTitle_player1 = menuItemTitle_player1
		self.menuItemTitle_player2 = menuItemTitle_player2
	}

	func menuItemTitle(menuMode: PlayerMenuMode) -> String {
		switch menuMode {
		case .player1:
			return menuItemTitle_player1
		case .player2:
			return menuItemTitle_player2
		}
	}
}

public class PlayerRoleMenuItemFactory {
	public static var shared = PlayerRoleMenuItemFactory()

	public lazy var none: PlayerRoleMenuItem = {
		PlayerRoleMenuItemImpl(
			role: .none,
			userDefaultIdentifier: "none",
			menuItemTitle: "None"
		)
	}()

	public lazy var human: PlayerRoleMenuItem = {
		PlayerRoleMenuItemWithCustomTitleImpl(
			role: .human,
			userDefaultIdentifier: "human",
			menuItemTitle_player1: "Human - Arrows",
			menuItemTitle_player2: "Human - WASD"
		)
	}()

	public lazy var bots: [PlayerRoleMenuItem] = {
		var registered = [PlayerRoleMenuItem]()
		for snakeBotType: SnakeBot.Type in SnakeBotFactory.snakeBotTypes {
			let info: SnakeBotInfo = snakeBotType.info
			let playerRoleMenuItem = PlayerRoleMenuItemImpl(
				role: SnakePlayerRole.bot(snakeBotType: snakeBotType),
                userDefaultIdentifier: info.id.uuidString,
				menuItemTitle: "Bot - \(info.humanReadableName)"
			)
			registered.append(playerRoleMenuItem)
		}
		return registered
	}()

	public lazy var allCases: [PlayerRoleMenuItem] = {
		var array = [PlayerRoleMenuItem]()
		array.append(self.none)
		array.append(self.human)
		array += self.bots
		return array
	}()

	public func find(userDefaultIdentifier: String) -> PlayerRoleMenuItem? {
		for playerRoleMenuItem: PlayerRoleMenuItem in self.allCases {
			if playerRoleMenuItem.userDefaultIdentifier == userDefaultIdentifier {
				return playerRoleMenuItem
			}
		}
		return nil
	}

	public func defaultBotOrNone() -> PlayerRoleMenuItem {
		return self.bots.last ?? self.none
	}
}


extension UserDefaults {
	public var player1RoleMenuItem: PlayerRoleMenuItem {
		set {
			let string: String = newValue.userDefaultIdentifier
			self.set(string, forKey: "player1RoleMenuItem")
			FlowEvent_DidChangePlayerSetting().fire()
		}
		get {
			guard let string: String = self.string(forKey: "player1RoleMenuItem") else {
				return PlayerRoleMenuItemFactory.shared.human
			}
			guard let playerRoleMenuItem: PlayerRoleMenuItem = PlayerRoleMenuItemFactory.shared.find(userDefaultIdentifier: string) else {
				return PlayerRoleMenuItemFactory.shared.human
			}
			return playerRoleMenuItem
		}
	}

	public var player2RoleMenuItem: PlayerRoleMenuItem {
		set {
			let string: String = newValue.userDefaultIdentifier
			self.set(string, forKey: "player2RoleMenuItem")
			FlowEvent_DidChangePlayerSetting().fire()
		}
		get {
			guard let string: String = self.string(forKey: "player2RoleMenuItem") else {
				return PlayerRoleMenuItemFactory.shared.defaultBotOrNone()
			}
			guard let playerRoleMenuItem: PlayerRoleMenuItem = PlayerRoleMenuItemFactory.shared.find(userDefaultIdentifier: string) else {
				return PlayerRoleMenuItemFactory.shared.defaultBotOrNone()
			}
			return playerRoleMenuItem
		}
	}
}

public class PlayerMenu: NSMenu {
	public func configureAsPlayer1() {
		configure(menuMode: .player1)
	}

	public func configureAsPlayer2() {
		configure(menuMode: .player2)
	}

	private var menuMode = PlayerMenuMode.player1

	private func configure(menuMode: PlayerMenuMode) {
		self.menuMode = menuMode
		self.removeAllItems()

		for role: PlayerRoleMenuItem in PlayerRoleMenuItemFactory.shared.allCases {
			let item = NSMenuItem()
			item.title = role.menuItemTitle(menuMode: menuMode)
			item.target = self
			item.action = #selector(roleAction)
			item.representedObject = role
			self.addItem(item)
		}

		updateSelection()
	}

	private func updateSelection() {
		let selectedRole: PlayerRoleMenuItem = self.selectedRoleMenuItem
		for item: NSMenuItem in self.items {
			if item.isSeparatorItem {
				continue
			}
			guard let representedObject: Any = item.representedObject else {
                log.error("Menu item does not have a representedObject")
				continue
			}
			if let itemRole = item.representedObject as? PlayerRoleMenuItem {
				if itemRole.userDefaultIdentifier == selectedRole.userDefaultIdentifier {
					item.state = .on
				} else {
					item.state = .off
				}
				continue
			}
			log.error("Expected item.representedObject to be PlayerRoleMenuItem, but got: \(type(of: representedObject))")
		}
	}

	@objc private func roleAction(_ sender: NSMenuItem) {
		guard let role: PlayerRoleMenuItem = sender.representedObject as? PlayerRoleMenuItem else {
			log.error("Expected sender.representedObject to be a PlayerRoleMenuItem, but got nil.")
			return
		}
		self.selectedRoleMenuItem = role
		updateSelection()
	}

	private var selectedRoleMenuItem: PlayerRoleMenuItem {
		set {
			switch self.menuMode {
			case .player1:
				UserDefaults.standard.player1RoleMenuItem = newValue
			case .player2:
				UserDefaults.standard.player2RoleMenuItem = newValue
			}
		}
		get {
			switch self.menuMode {
			case .player1:
				return UserDefaults.standard.player1RoleMenuItem
			case .player2:
				return UserDefaults.standard.player2RoleMenuItem
			}
		}
	}
}
