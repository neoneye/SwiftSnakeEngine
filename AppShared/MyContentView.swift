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

    @State var model: GameViewModel
    @ObservedObject var levelSelectorViewModel: LevelSelectorViewModel
    @State var visibleContent = MyContentView_VisibleContent.levelSelector

    #if os(macOS)
    @Environment(\.keyPublisher) var keyPublisher
    #endif

    @State private var player1Dead: Bool = false
    @State private var player2Dead: Bool = false
    @State var presentingModal = false
    var isPreview: Bool = false
    let player1ColorAlive: Color = AppColor.player1_snakeBody.color
    let player2ColorAlive: Color = AppColor.player2_snakeBody.color

    let showDebugPanels = false

    var player1Color: Color {
        if player1Dead {
            return player1ColorAlive.opacity(0.3)
        } else {
            return player1ColorAlive
        }
    }

    var player2Color: Color {
        if player2Dead {
            return player2ColorAlive.opacity(0.3)
        } else {
            return player2ColorAlive
        }
    }

    var debugPanel1: some View {
        HStack {
            Button("Dead/Alive") {
                self.player1Dead.toggle()
            }
            Button("+") {
                let length: UInt = self.model.player1Length
                self.model.player1Length = length + 1
            }
            Button("-") {
                let length: UInt = self.model.player1Length
                if length >= 1 {
                    self.model.player1Length = length - 1
                }
            }
        }
    }

    var debugPanel2: some View {
        HStack {
            Button("Dead/Alive") {
                self.player2Dead.toggle()
            }
            Button("+") {
                let length: UInt = self.model.player2Length
                self.model.player2Length = length + 1
            }
            Button("-") {
                let length: UInt = self.model.player2Length
                if length >= 1 {
                    self.model.player2Length = length - 1
                }
            }
        }
    }

    var stripeImage: some View {
        Image("stripes")
            .resizable(resizingMode: .tile)
            .contrast(0.2)
            .colorMultiply(Color(white: 0.3))
    }

    var leftSide: some View {
        HStack(spacing: 1) {
            VStack(alignment: .leading, spacing: 0) {

                Text(model.player1Info)
                    .padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(self.player1Color)
                    .foregroundColor(.black)

                if self.showDebugPanels {
                    debugPanel1
                }

            }

            if model.player1Length >= 1 {
                PlayerScoreView(
                    playerLength: $model.player1Length,
                    color: self.player1Color
                )
            }
        }
    }

    var rightSide: some View {
        HStack(spacing: 1) {
            if model.player2Length >= 1 {
                PlayerScoreView(
                    playerLength: $model.player2Length,
                    color: self.player2Color
                )
            }

            VStack(alignment: .leading, spacing: 0) {

                Text(model.player2Info)
                    .padding(10)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .background(self.player2Color)
                    .foregroundColor(.black)

                if self.showDebugPanels {
                    debugPanel2
                }
            }
        }
    }

    var leftSideOpacity: Double {
        if model.player1Length >= 1 {
            return 1
        } else {
            return 0
        }
    }

    var rightSideOpacity: Double {
        if model.player2Length >= 1 {
            return 1
        } else {
            return 0
        }
    }

    private var spriteKitContainer: SpriteKitContainer {
        SpriteKitContainer(
            model: self.model,
            isPreview: self.isPreview
        )
    }

    private var ingameView: some View {
        IngameView(
            model: model,
            mode: .playable
        )
    }

    func launchGame(_ gameViewModel: GameViewModel) {
//        self.model = GameViewModel.createReplay()
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
//        case .letterT:
//            let url: URL = gameState.saveTrainingData(trainingSessionUUID: self.trainingSessionUUID)
//            trainingSessionURLs.append(url)
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

    private var pauseButton: some View {
        Button(action: {
            log.debug("pause button pressed")
            self.presentingModal = true
        }) {
            Image("ingame_pauseButton_image")
                .foregroundColor(AppColor.ingame_pauseButton.color)
                .scaleEffect(0.6)
                .padding(15)
        }
        .sheet(isPresented: $presentingModal) {
            PauseSheetView(model: self.model, presentedAsModal: self.$presentingModal)
        }
    }

    private var iOS_overlayWithPauseButton: some View {
        VStack {
            HStack {
                pauseButton
                Spacer()
            }
            Spacer()
        }
    }

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
                Text("Battle the AI")
                    .foregroundColor(.primary)
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Toggle("Battle the AI", isOn: bindingOn)
                .labelsHidden()
            }
            .padding(EdgeInsets(top: 30, leading: 30, bottom: 10, trailing: 30))

        }
        .frame(minWidth: 80, maxWidth: .infinity)
        .modifier(ViewHeightGetter())
        .onPreferenceChange(ViewHeightPreferenceKey.self) { [weak model] (viewHeight: CGFloat) in
            log.debug("height of view: \(viewHeight)")
            model?.levelSelector_insetTop = viewHeight
        }
        .background(AppColor.levelSelector_header.color)
    }

    private var iOS_overlayWithHeader: some View {
        return VStack {
            iOS_overlayWithHeader_inner

            Spacer()
        }
        .foregroundColor(Color.black)
    }

    private var macOS_footer: some View {
        ZStack {
            stripeImage

            HStack(spacing: 1) {

                leftSide
                    .opacity(leftSideOpacity)
                    .frame(maxWidth: .infinity)

                rightSide
                    .opacity(rightSideOpacity)
                    .frame(maxWidth: .infinity)

            }

        }
        .frame(minWidth: 80, maxWidth: .infinity, minHeight: 80, maxHeight: 100)
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
        VStack(spacing: 1) {

            if AppConstant.useSwiftUIInsteadOfSpriteKit {
                mainContent
            } else {
                spriteKitContainer
                macOS_footer
            }

        }
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: isPreview ? 100 : 400, maxWidth: .infinity, minHeight: isPreview ? 80 : 400, maxHeight: .infinity)
    }

    var iOS_body: some View {
        ZStack {
            if AppConstant.useSwiftUIInsteadOfSpriteKit {
                mainContent
            } else {
                spriteKitContainer

                if model.showPauseButton {
                    iOS_overlayWithPauseButton
                }

                if model.levelSelector_visible {
                    iOS_overlayWithHeader
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: isPreview ? 100 : 400, maxWidth: .infinity, minHeight: isPreview ? 80 : 400, maxHeight: .infinity)
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
    }
}

struct ContentView_Previews : PreviewProvider {

    static var previews: some View {
        let model = GameViewModel.create()
        let levelSelectorViewModel = LevelSelectorViewModel()
        levelSelectorViewModel.useMockData()
        let settingStore = SettingStore()
        return Group {
//            MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, isPreview: true)
//                .previewLayout(.fixed(width: 130, height: 200))

            MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, isPreview: true)
                .previewLayout(.fixed(width: 500, height: 500))

//            MyContentView(model: model, levelSelectorViewModel: levelSelectorViewModel, isPreview: true)
//                .previewLayout(.fixed(width: 500, height: 150))
        }
        .environmentObject(settingStore)
    }

}
