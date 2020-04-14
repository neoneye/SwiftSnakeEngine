// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import EngineIOS

class GameViewController: UIHostingController<MyContentView> {

    static func create() -> GameViewController {
        let model = MyModel()
        let view = MyContentView(model: model)
        return GameViewController(rootView: view)
    }

    override init(rootView: MyContentView) {
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
