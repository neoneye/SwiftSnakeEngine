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
    @State var isDragging = false
    let hasPauseButton: Bool

    enum TouchMoveDirection {
        case undecided
        case horizontal
        case vertical
    }
    @State var touchMoveDirection = TouchMoveDirection.undecided
    @State var dragOffset: CGSize = .zero


    private var drag: some Gesture {
        DragGesture()
            .onChanged { v in
                if !self.isDragging {
                    self.isDragging = true
                    self.touchMoveDirection = TouchMoveDirection.undecided
                    log.debug("began. startLocation: \(v.startLocation)")

                } else {
                    log.debug("changed. startLocation: \(v.startLocation)")
                }
                self.dragOffset = v.translation
            }
            .onEnded { v in
                self.isDragging = false

                log.debug("ended. startLocation: \(v.startLocation)")
            }
    }

    var body: some View {
        return ZStack {
            innerBodyWithAspectRatio

            if hasPauseButton {
                overlayWithPauseButton
            }
        }
        .gesture(drag)
    }

    var innerBodyWithAspectRatio: some View {
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
            IngameView(model: model, hasPauseButton: true)
                .previewLayout(.fixed(width: 130, height: 200))
            IngameView(model: model, hasPauseButton: true)
                .previewLayout(.fixed(width: 300, height: 200))
            IngameView(model: model, hasPauseButton: true)
                .previewLayout(.fixed(width: 400, height: 150))
        }
    }
}
