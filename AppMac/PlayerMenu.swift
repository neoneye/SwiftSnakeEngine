// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Cocoa
import SSEventFlow
import EngineMac

class FlowEvent_DidChangePlayerSetting: FlowEvent {}

public enum PlayerMenuMode {
	case player1, player2
}

public protocol PlayerRoleMenuItem {
    var id: UUID { get }
	var role: SnakePlayerRole { get }
	func menuItemTitle(menuMode: PlayerMenuMode) -> String
}

private class PlayerRoleMenuItemImpl: PlayerRoleMenuItem {
    let id: UUID
	let role: SnakePlayerRole
	let menuItemTitle: String

	init(id: UUID, role: SnakePlayerRole, menuItemTitle: String) {
        self.id = id
		self.role = role
		self.menuItemTitle = menuItemTitle
	}

	func menuItemTitle(menuMode: PlayerMenuMode) -> String {
		return self.menuItemTitle
	}
}

private class PlayerRoleMenuItemWithCustomTitleImpl: PlayerRoleMenuItem {
    let id: UUID
	let role: SnakePlayerRole
	let menuItemTitle_player1: String
	let menuItemTitle_player2: String

	init(id: UUID, role: SnakePlayerRole, menuItemTitle_player1: String, menuItemTitle_player2: String) {
        self.id = id
		self.role = role
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
            id: SnakePlayerRole.none.id,
			role: .none,
			menuItemTitle: "None"
		)
	}()

	public lazy var human: PlayerRoleMenuItem = {
		PlayerRoleMenuItemWithCustomTitleImpl(
            id: SnakePlayerRole.human.id,
			role: .human,
			menuItemTitle_player1: "Human - Arrows",
			menuItemTitle_player2: "Human - WASD"
		)
	}()

	public lazy var bots: [PlayerRoleMenuItem] = {
		var registered = [PlayerRoleMenuItem]()
        for snakeBotType: SnakeBot.Type in SnakeBotFactory.shared.macOSPlayerMenuTypes {
			let info: SnakeBotInfo = snakeBotType.info
			let playerRoleMenuItem = PlayerRoleMenuItemImpl(
                id: info.id,
				role: SnakePlayerRole.bot(snakeBotType: snakeBotType),
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

	public func find(id: UUID) -> PlayerRoleMenuItem? {
		for playerRoleMenuItem: PlayerRoleMenuItem in self.allCases {
			if playerRoleMenuItem.id == id {
				return playerRoleMenuItem
			}
		}
		return nil
	}

	fileprivate func smartestBotOrNone() -> PlayerRoleMenuItem {
        let id: UUID = SnakeBotFactory.smartestBotType().info.id
        guard let menuItem: PlayerRoleMenuItem = self.find(id: id) else {
            return self.none
        }
		return menuItem
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
				if itemRole.id == selectedRole.id {
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
                SettingPlayer1Role().set(newValue.role)
			case .player2:
                SettingPlayer2Role().set(newValue.role)
			}
            FlowEvent_DidChangePlayerSetting().fire()
		}
		get {
            let role: SnakePlayerRole
			switch self.menuMode {
			case .player1:
                role = SettingPlayer1Role().value
			case .player2:
                role = SettingPlayer2Role().value
			}
            guard let playerRoleMenuItem: PlayerRoleMenuItem = PlayerRoleMenuItemFactory.shared.find(id: role.id) else {
                return PlayerRoleMenuItemFactory.shared.human
            }
            return playerRoleMenuItem
		}
	}
}
