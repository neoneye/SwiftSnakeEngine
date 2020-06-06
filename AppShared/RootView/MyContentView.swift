// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI
import Combine

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

enum MyContentView_VisibleContent {
    case levelSelector
    case ingame
}

struct MyContentView: View {
    @EnvironmentObject var settingStore: SettingStore

    @State var model: IngameViewModel
    @ObservedObject var levelSelectorViewModel: LevelSelectorViewModel
    @State var visibleContent: MyContentView_VisibleContent

    #if os(macOS)
    @Environment(\.keyPublisher) var keyPublisher
    #endif

    @State var presentingModal = false
    var isPreview: Bool = false

    private var ingameView: some View {
        IngameView(
            model: model,
            mode: .playable
        )
    }

    func launchGame(_ gameViewModel: IngameViewModel) {
//        self.model = IngameViewModel.createReplay()
        self.model = gameViewModel.toInteractiveModel()
        self.visibleContent = .ingame
    }

    private var innerLevelSelectorView: some View {
        let selectLevelHandler: SelectLevelHandler = { cell in
            //log.debug("did select model: \(cell.id)")
            if self.levelSelectorViewModel.selectedIndex == cell.id {
                self.launchGame(cell.model)
            } else {
                self.settingStore.selectedLevel = cell.id
                self.levelSelectorViewModel.selectedIndex = cell.id
                self.model = cell.model
            }
        }
        return LevelSelectorView(
            levelSelectorViewModel: levelSelectorViewModel,
            selectLevelHandler: selectLevelHandler
        )
        .onReceive(settingStore.objectWillChange) { _ in
            log.debug("did change settings")
            self.levelSelectorViewModel.loadModelsFromUserDefaults()
        }
    }

    private var macOS_levelSelectorView: some View {
        return innerLevelSelectorView
    }

    private var iOS_levelSelectorView: some View {
        VStack {
            iOS_overlayWithHeader_inner

            innerLevelSelectorView

            Spacer()
        }
    }

    private var levelSelectorView: some View {
        #if os(macOS)
        return macOS_levelSelectorView
        #else
        return iOS_levelSelectorView
        #endif
    }

    #if os(macOS)
    func keyPressed(with event: NSEvent) {
        guard event.type == NSEvent.EventType.keyDown else {
            return
        }

        if AppConstant.ignoreRepeatingKeyDownEvents && event.isARepeat {
            //log.debug("keyDown: ignoring repeating event.")
            return
        }

        switch event.keyCodeEnum {
        case .escape:
            if AppConstant.escapeKeyToTerminateApp {
                log.debug("ESCape key to terminate app")
                NSApp.terminate(self)
                return
            }
        default:
            ()
        }

        switch visibleContent {
        case .levelSelector:
            keyPressed_levelSelector(with: event)
        case .ingame:
            keyPressed_ingame(with: event)
        }
    }

    func keyPressed_levelSelector(with event: NSEvent) {
        switch event.keyCodeEnum {
        case .escape:
            NSApp.terminate(self)
        case .enter:
            if let model = levelSelectorViewModel.gameViewModelForSelectedIndex() {
                self.launchGame(model)
            }
        case .arrowUp:
            levelSelectorViewModel.moveSelectionUp()
            settingStore.selectedLevel = levelSelectorViewModel.selectedIndex
        case .arrowLeft:
            levelSelectorViewModel.moveSelectionLeft()
            settingStore.selectedLevel = levelSelectorViewModel.selectedIndex
        case .arrowRight:
            levelSelectorViewModel.moveSelectionRight()
            settingStore.selectedLevel = levelSelectorViewModel.selectedIndex
        case .arrowDown:
            levelSelectorViewModel.moveSelectionDown()
            settingStore.selectedLevel = levelSelectorViewModel.selectedIndex
        default:
            log.debug("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }

    func keyPressed_ingame(with event: NSEvent) {
        switch event.keyCodeEnum {
        case .letterW:
            model.userInputForPlayer2(.up)
        case .letterA:
            model.userInputForPlayer2(.left)
        case .letterS:
            model.userInputForPlayer2(.down)
        case .letterD:
            model.userInputForPlayer2(.right)
        case .letterM:
            model.singleStep_botsOnly()
        case .letterZ:
            model.undo()
        case .enter:
            model.restartGame()
        case .tab:
            model.restartGame()
        case .spacebar:
            model.toggleStepMode()
        case .escape:
            self.visibleContent = .levelSelector
        case .arrowUp:
            model.userInputForPlayer1(.up)
        case .arrowLeft:
            model.userInputForPlayer1(.left)
        case .arrowRight:
            model.userInputForPlayer1(.right)
        case .arrowDown:
            model.userInputForPlayer1(.down)
        default:
            log.debug("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    #endif

    private var iOS_overlayWithHeader_inner: some View {
        // Translation between boolean <-> playerMode enum.
        let bindingOn = Binding<Bool> (
            get: {
                (self.settingStore.playerMode == .twoPlayer_humanBot)
            },
            set: { newValue in
                if newValue {
                    self.settingStore.playerMode = .twoPlayer_humanBot
                } else {
                    self.settingStore.playerMode = .singlePlayer_human
                }
            }
        )

        return VStack {
            HStack {
                Text("Human + Robot")
                    .foregroundColor(.primary)
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Toggle("Human + Robot", isOn: bindingOn)
                .labelsHidden()
            }
            .padding(EdgeInsets(top: 30, leading: 30, bottom: 10, trailing: 30))

        }
        .frame(minWidth: 80, maxWidth: .infinity)
    }

    private var iOS_overlayWithHeader: some View {
        return VStack {
            iOS_overlayWithHeader_inner

            Spacer()
        }
        .foregroundColor(Color.black)
    }

    var mainContent: some View {
        switch visibleContent {
        case .levelSelector:
            return AnyView(levelSelectorView)
        case .ingame:
            return AnyView(ingameView)
        }
    }

    var macOS_body: some View {
        mainContent
        .frame(minWidth: isPreview ? 100 : 400, maxWidth: .infinity, minHeight: isPreview ? 80 : 400, maxHeight: .infinity)
    }

    var iOS_body: some View {
        mainContent
    }

    var innerBody: some View {
        #if os(macOS)
        return macOS_body
            .onReceive(keyPublisher) { event in
                self.keyPressed(with: event)
            }
        #else
        return iOS_body
        #endif
    }

    var body: some View {
        innerBody
        .onReceive(model.jumpToLevelSelector) { _ in
            self.visibleContent = .levelSelector
        }
        .background(AppColor.levelSelector_background.color)
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews : PreviewProvider {

    static var previews: some View {
        let model = IngameViewModel.create()
        let levelSelectorViewModel = LevelSelectorViewModel()
        levelSelectorViewModel.useMockData()
        let settingStore = SettingStore()
        return Group {
//            MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, isPreview: true)
//                .previewLayout(.fixed(width: 130, height: 200))

            MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, visibleContent: .levelSelector, isPreview: true)
                .previewLayout(.fixed(width: 500, height: 500))

//            MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, isPreview: true)
//                .previewLayout(.fixed(width: 500, height: 150))
        }
        .environmentObject(settingStore)
    }

}
