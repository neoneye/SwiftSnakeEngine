// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct IngameView: View {
    @EnvironmentObject var settingStore: SettingStore
    @ObservedObject var model: IngameViewModel
    @State var presentingModal = false

    enum Mode {
        /// Interactive, drag gestures, pause button.
        case playable

        /// Non-interactive thumbnail of the level.
        case levelSelectorPreview

        /// Non-interactive replay of the game.
        case replayOnPauseSheet
    }
    let mode: Mode

    // MARK: - Drag gesture

    enum DragDirection {
        case undecided
        case horizontal
        case vertical
    }
    @State var dragDirection = DragDirection.undecided
    @State var dragOffset: CGSize = .zero
    @State var isDragging = false

    private func dragGesture(_ geometry: GeometryProxy) -> some Gesture {
        let gridSize: UIntVec2 = model.level.size
        let gridComputer = IngameGridComputer(viewSize: geometry.size, gridSize: gridSize)
        let tileMinSize: CGFloat = gridComputer.tileMinSize
        let minimumDistance: CGFloat = tileMinSize * 0.1
        let dragOffsetLimit: CGFloat = tileMinSize

        return DragGesture(minimumDistance: minimumDistance)
            .onChanged {
                self.dragGesture_onChanged(value: $0, minimumDistance: minimumDistance, dragOffsetLimit: dragOffsetLimit)
            }
            .onEnded {
                self.dragGesture_onEnded(value: $0, minimumDistance: minimumDistance)
            }
    }

    private func dragGesture_onChanged(value: DragGesture.Value, minimumDistance: CGFloat, dragOffsetLimit: CGFloat) {
        if !self.isDragging {
            let newDragDirection: DragDirection = determineDirection(value: value, minimumDistance: minimumDistance)
            if newDragDirection == .undecided {
                log.error("Inconsistency: DragGesture began, but distance is smaller than minimumDistance. Cannot determine direction.")
                return
            }

            self.dragDirection = newDragDirection
            self.isDragging = true
//            log.debug("began")
        }

        switch self.dragDirection {
        case .undecided:
            ()
        case .horizontal:
            dragGesture_onChanged_horizontal(value: value, dragOffsetLimit: dragOffsetLimit)
        case .vertical:
            dragGesture_onChanged_vertical(value: value, dragOffsetLimit: dragOffsetLimit)
        }
    }

    private func determineDirection(value: DragGesture.Value, minimumDistance: CGFloat) -> DragDirection {
        let gridPoint0: CGPoint = value.startLocation
        let gridPoint1: CGPoint = value.location
        let dx: CGFloat = gridPoint0.x - gridPoint1.x
        let dy: CGFloat = gridPoint0.y - gridPoint1.y
        let dx2: CGFloat = dx * dx
        let dy2: CGFloat = dy * dy
        let distance: CGFloat = sqrt(dx2 + dy2)
        guard distance > minimumDistance else {
            //log.debug("undecided direction. distance: \(distance.string2)  minimumDistance: \(minimumDistance)")
            return .undecided
        }
        if dx2 > dy2 {
            //log.debug("horizontal direction. distance: \(distance.string2)  minimumDistance: \(minimumDistance)")
            return .horizontal
        } else {
            //log.debug("vertical direction. distance: \(distance.string2)  minimumDistance: \(minimumDistance)")
            return .vertical
        }
    }

    func dragGesture_onChanged_horizontal(value: DragGesture.Value, dragOffsetLimit: CGFloat) {
        var offset: CGFloat = value.translation.width
        if offset < -dragOffsetLimit {
            offset = -dragOffsetLimit
        }
        if offset > dragOffsetLimit {
            offset = dragOffsetLimit
        }
        self.dragOffset = CGSize(width: offset, height: 0)
    }

    func dragGesture_onChanged_vertical(value: DragGesture.Value, dragOffsetLimit: CGFloat) {
        var offset: CGFloat = value.translation.height
        if offset < -dragOffsetLimit {
            offset = -dragOffsetLimit
        }
        if offset > dragOffsetLimit {
            offset = dragOffsetLimit
        }
        self.dragOffset = CGSize(width: 0, height: offset)
    }

    private func dragGesture_onEnded(value: DragGesture.Value, minimumDistance: CGFloat) {
        log.debug("ended. direction: \(self.dragDirection)")
        self.isDragging = false
        switch self.dragDirection {
        case .undecided:
            log.debug("do nothing")
        case .horizontal:
            dragGesture_onEnded_horizontal(value: value, minimumDistance: minimumDistance)
        case .vertical:
            dragGesture_onEnded_vertical(value: value, minimumDistance: minimumDistance)
        }
    }

    private func dragGesture_onEnded_horizontal(value: DragGesture.Value, minimumDistance: CGFloat) {
        let gridPoint0: CGPoint = value.startLocation
        let gridPoint1: CGPoint = value.location
        let dx: CGFloat = gridPoint0.x - gridPoint1.x
        let dx2: CGFloat = dx * dx
        let distance: CGFloat = sqrt(dx2)
        guard distance > minimumDistance else {
            return
        }

        if dx > 0 {
            self.model.userInputForPlayer1(.left)
        }
        if dx < 0 {
            self.model.userInputForPlayer1(.right)
        }
    }

    private func dragGesture_onEnded_vertical(value: DragGesture.Value, minimumDistance: CGFloat) {
        let gridPoint0: CGPoint = value.startLocation
        let gridPoint1: CGPoint = value.location
        let dy: CGFloat = gridPoint0.y - gridPoint1.y
        let dy2: CGFloat = dy * dy
        let distance: CGFloat = sqrt(dy2)
        guard distance > minimumDistance else {
            return
        }

        if dy > 0 {
            self.model.userInputForPlayer1(.up)
        }
        if dy < 0 {
            self.model.userInputForPlayer1(.down)
        }
    }

    private var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
//                log.debug("tap")
                self.model.userInputForPlayer1_moveForward()
            }
    }

    var body: some View {
        switch self.mode {
        case .playable:
            return AnyView(playableMode_body)
        case .levelSelectorPreview:
            return AnyView(innerBodyWithAspectRatio)
        case .replayOnPauseSheet:
            return AnyView(replayView)
        }
    }

    private func playableMode_body_inner(_ geometry: GeometryProxy) -> some View {
        return ZStack {
            Rectangle()
                .foregroundColor(AppColor.theme1_wall.color)

            innerBodyWithAspectRatio

            overlayWithPauseButton
        }
        .gesture(tapGesture)
        .highPriorityGesture(dragGesture(geometry))
        .onAppear {
            self.model.ingameView_playableMode_onAppear()
        }
        .onDisappear {
            self.model.ingameView_playableMode_onDisappear()
        }
    }

    private var playableMode_body: some View {
        GeometryReader { geometry in
            self.playableMode_body_inner(geometry)
        }
    }

    private var replayView: some View {
        innerBodyWithAspectRatio
        .onAppear {
            self.model.ingameView_replayMode_onAppear()
        }
        .onDisappear {
            self.model.ingameView_replayMode_onDisappear()
        }
    }

    private var innerBodyWithAspectRatio: some View {
        return ZStack {
            backgroundSolid

            LevelView(model: model)

            food

            player1_snakeBody
            player2_snakeBody

            if isShowPlannedPathEnabledForThisMode {
                player1_plannedPath
                player2_plannedPath
            }

            if isDragging {
                gestureIndicator
            }

        }.aspectRatio(self.aspectRatio, contentMode: .fit)
    }

    private var aspectRatio: CGSize {
        let levelSize: UIntVec2 = model.level.size
        var x = Int(levelSize.x)
        var y = Int(levelSize.y)
        if IngameGridComputer.trimEdges {
            x -= 2
            y -= 2
        }
        x = max(x, 1)
        y = max(y, 1)
        return CGSize(width: CGFloat(x), height: CGFloat(y))
    }

    private var backgroundSolid: some View {
        Rectangle()
            .foregroundColor(AppColor.theme1_wall.color)
            .edgesIgnoringSafeArea(.all)
    }

    private var food: some View {
        FoodView(
            gridSize: .constant(model.level.size),
            foodPosition: $model.foodPosition
        )
    }

    private var player1_snakeBody: some View {
        guard model.player1IsInstalled else {
            return AnyView(EmptyView())
        }
        let color: Color
        if model.player1IsAlive {
            color = AppColor.player1_snakeBody.color
        } else {
            color = AppColor.player1_snakeBody_dead.color
        }
        let view = SnakeBodyView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player1SnakeBody,
            fillColor: color
        )
        return AnyView(view)
    }

    private var player2_snakeBody: some View {
        guard model.player2IsInstalled else {
            return AnyView(EmptyView())
        }
        let color: Color
        if model.player2IsAlive {
            color = AppColor.player2_snakeBody.color
        } else {
            color = AppColor.player2_snakeBody_dead.color
        }
        return AnyView(SnakeBodyView(
            gridSize: .constant(model.level.size),
            snakeBody: $model.player2SnakeBody,
            fillColor: color
        ))
    }

    private var isShowPlannedPathEnabledForThisMode: Bool {
        #if os(macOS)

        guard mode == .playable else {
            return false
        }
        guard settingStore.isShowPlannedPathEnabled else {
            return false
        }
        // The developer have enabled planned path visualization.
        return true

        #else

        // Planned path is always hidden on iOS.
        return false
        #endif
    }

    private var player1_plannedPath: some View {
        let colorHighConfidence: Color = AppColor.player1_plannedPath.color
        let colorLowConfidence: Color = colorHighConfidence.opacity(0.5)
        return PlannedPathView(
            colorHighConfidence: colorHighConfidence,
            colorLowConfidence: colorLowConfidence,
            gridSize: .constant(model.level.size),
            positionArray: $model.player1PlannedPath,
            foodPosition: $model.foodPosition
        )
    }

    private var player2_plannedPath: some View {
        let colorHighConfidence: Color = AppColor.player2_plannedPath.color
        let colorLowConfidence: Color = colorHighConfidence.opacity(0.5)
        return PlannedPathView(
            colorHighConfidence: colorHighConfidence,
            colorLowConfidence: colorLowConfidence,
            gridSize: .constant(model.level.size),
            positionArray: $model.player2PlannedPath,
            foodPosition: $model.foodPosition
        )
    }

    private var gestureIndicator: some View {
        return GestureIndicatorView(
            gridSize: .constant(model.level.size),
            headPosition: $model.gestureIndicatorPosition
        )
        .offset(dragOffset)
    }

    private var pauseButton: some View {
        Button(action: {
            self.model.ingameView_willPresentPauseSheet()
            self.presentingModal = true
        }) {
            Image("ingame_pauseButton_image")
                .foregroundColor(AppColor.ingame_pauseButton.color)
                .scaleEffect(0.6)
                .padding(15)
        }
        .buttonStyle(BorderlessButtonStyle())
        .sheet(isPresented: $presentingModal, content: buildPauseSheetContent)
    }

    private func buildPauseSheetContent() -> some View {
        guard let replayModel: IngameViewModel = self.model.replayGameViewModel else {
            log.error("There is no replay data to be replayed")
            fatalError()
        }
        return PauseSheetView(
            model: self.model,
            replayModel: replayModel,
            presentedAsModal: self.$presentingModal
        )
        .environmentObject(self.settingStore)
    }

    private var overlayWithPauseButton: some View {
        VStack {
            HStack {
                pauseButton
                Spacer()
            }
            Spacer()
        }
    }
}

struct IngameView_Previews: PreviewProvider {
    static var previews: some View {
        let settingStore = SettingStore()
        let model = IngameViewModel.createHumanVsHuman()
        return Group {
            IngameView(model: model, mode: .playable)
                .previewLayout(.fixed(width: 130, height: 200))
            IngameView(model: model, mode: .playable)
                .previewLayout(.fixed(width: 300, height: 200))
            IngameView(model: model, mode: .playable)
                .previewLayout(.fixed(width: 400, height: 150))
        }
        .environmentObject(settingStore)
    }
}
