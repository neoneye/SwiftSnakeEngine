// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import EngineIOS

class GameViewController: UIHostingController<MyContentView> {

    static func create() -> GameViewController {
        let playerMode: PlayerMode = PlayerModeController().value
        let initialValue: Bool
        switch playerMode {
        case .twoPlayer_humanBot:
            initialValue = true
        case .singlePlayer_human:
            initialValue = false
        }

        let settingStore = SettingStore()

        let levelSelectorViewModel = LevelSelectorViewModel()
        levelSelectorViewModel.loadModelsFromUserDefaults()
        levelSelectorViewModel.selectedIndex = settingStore.selectedLevel

        let model = GameViewModel.create()
        model.levelSelector_humanVsBot = initialValue
        let view = MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, settingStore: settingStore)
        return GameViewController(rootView: view)
    }

    override init(rootView: MyContentView) {
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Light/Dark appearance

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard UIApplication.shared.applicationState == .inactive else {
            //log.debug("the app is inactive, ignoring")
            return
        }
        let oldStyle: UIUserInterfaceStyle? = previousTraitCollection?.userInterfaceStyle
        let newStyle: UIUserInterfaceStyle = traitCollection.userInterfaceStyle
        if oldStyle != newStyle {
            updateImageForCurrentTraitCollection()
        }
    }

    private func updateImageForCurrentTraitCollection() {
        switch traitCollection.userInterfaceStyle {
        case .dark:
            log.debug("new style dark")
        case .light:
            log.debug("new style light")
        default:
            log.debug("did change. unknown style: \(traitCollection.userInterfaceStyle.rawValue)")
        }
        self.rootView.model.userInterfaceStyle.send()
    }

    // MARK: - Status bar

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Keyboard handling

    // Listening for keyboard events.
    override func becomeFirstResponder() -> Bool {
        true
    }

    override var keyCommands: [UIKeyCommand]? {
        return  [
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(upPressed)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(downPressed)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(leftPressed)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(rightPressed)),
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(enterPressed)),
        ]
    }

    @objc func upPressed() {
        log.debug("Up")
    }

    @objc func downPressed() {
        log.debug("Down")
    }

    @objc func leftPressed() {
        log.debug("Left")
    }

    @objc func rightPressed() {
        log.debug("Right")
    }

    @objc func enterPressed() {
        log.debug("Enter")
    }
}
