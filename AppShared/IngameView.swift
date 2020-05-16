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
    @ObservedObject var model: GameViewModel
    @State var presentingModal = false

    enum Mode {
        /// Interactive, drag gestures, pause button.
        case playable

        /// Non-interactive thumbnail of the level.
        case levelSelectorPreview
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

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged {
                self.dragGesture_onChanged($0)
            }
            .onEnded {
                self.dragGesture_onEnded($0)
            }
    }

    private func dragGesture_onChanged(_ value: DragGesture.Value) {
        if !self.isDragging {
            self.isDragging = true
            self.dragDirection = DragDirection.undecided
            //log.debug("began. startLocation: \(value.startLocation)")

        } else {
            //log.debug("changed. startLocation: \(value.startLocation)")
        }
        self.dragOffset = value.translation

        switch self.dragDirection {
        case .undecided:
            dragGesture_onChanged_undecided(value)
        case .horizontal:
            ()
//            dragGesture_onChanged_horizontal(value)
        case .vertical:
            ()
//            dragGesture_onChanged_vertical(value)
        }
    }

    private func dragGesture_onChanged_undecided(_ value: DragGesture.Value) {
        let gridPoint0: CGPoint = value.startLocation
        let gridPoint1: CGPoint = value.location
        let dx: CGFloat = gridPoint0.x - gridPoint1.x
        let dy: CGFloat = gridPoint0.y - gridPoint1.y
        let dx2: CGFloat = dx * dx
        let dy2: CGFloat = dy * dy
        let distance: CGFloat = sqrt(dx2 + dy2)
        guard distance > 10 else {
            log.debug("undecided distance: \(distance.string2)")
            return
        }
        if dx2 > dy2 {
            dragDirection = .horizontal
            log.debug("moving horizontal")
        } else {
            dragDirection = .vertical
            log.debug("moving vertical")
        }
    }

    private func dragGesture_onEnded(_ value: DragGesture.Value) {
        log.debug("ended. direction: \(self.dragDirection)")
        self.isDragging = false
        switch self.dragDirection {
        case .undecided:
            log.debug("do nothing")
        case .horizontal:
            dragGesture_onEnded_horizontal(value)
        case .vertical:
            dragGesture_onEnded_vertical(value)
        }
    }

    private func dragGesture_onEnded_horizontal(_ value: DragGesture.Value) {
        let gridPoint0: CGPoint = value.startLocation
        let gridPoint1: CGPoint = value.location
        let dx: CGFloat = gridPoint0.x - gridPoint1.x
        let dx2: CGFloat = dx * dx
        let distance: CGFloat = sqrt(dx2)
        guard distance > 10 else {
            return
        }

        if dx > 0 {
            self.model.userInputForPlayer1(.left)
        }
        if dx < 0 {
            self.model.userInputForPlayer1(.right)
        }
    }

    private func dragGesture_onEnded_vertical(_ value: DragGesture.Value) {
        let gridPoint0: CGPoint = value.startLocation
        let gridPoint1: CGPoint = value.location
        let dy: CGFloat = gridPoint0.y - gridPoint1.y
        let dy2: CGFloat = dy * dy
        let distance: CGFloat = sqrt(dy2)
        guard distance > 10 else {
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
        }
    }

    private var playableMode_body: some View {
        return ZStack {
            Rectangle()
                .fill(AppColor.theme1_wall.color)

            innerBodyWithAspectRatio

            overlayWithPauseButton
        }
        .gesture(tapGesture)
        .gesture(dragGesture)
        .onAppear {
            self.model.ingameView_playableMode_onAppear()
        }
    }

    private var innerBodyWithAspectRatio: some View {
        return ZStack {
            backgroundSolid

            LevelView(model: model)

            food

            player1_snakeBody
            player2_snakeBody

            player1_plannedPath
            player2_plannedPath

            if isDragging {
                gestureIndicator
            }

        }.aspectRatio(self.aspectRatio, contentMode: .fit)
    }

    private var aspectRatio: CGSize {
        let levelSize: UIntVec2 = model.level.size
        return CGSize(width: CGFloat(levelSize.x), height: CGFloat(levelSize.y))
    }

    private var backgroundSolid: some View {
        Rectangle()
            .foregroundColor(AppColor.theme1_floor.color)
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
        if model.player1IsAlive {
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

    private var player1_plannedPath: PlannedPathView {
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

    private var player2_plannedPath: PlannedPathView {
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
            self.presentingModal = true
        }) {
            Image("ingame_pauseButton_image")
                .foregroundColor(AppColor.ingame_pauseButton.color)
                .scaleEffect(0.6)
                .padding(15)
        }
        .buttonStyle(BorderlessButtonStyle())
        .sheet(isPresented: $presentingModal) {
            PauseSheetView(model: self.model, presentedAsModal: self.$presentingModal)
        }
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
        let model = GameViewModel.createHumanVsHuman()
        return Group {
            IngameView(model: model, mode: .playable)
                .previewLayout(.fixed(width: 130, height: 200))
            IngameView(model: model, mode: .playable)
                .previewLayout(.fixed(width: 300, height: 200))
            IngameView(model: model, mode: .playable)
                .previewLayout(.fixed(width: 400, height: 150))
        }
    }
}
