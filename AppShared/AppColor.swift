// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

enum AppColor: String {
    case levelSelector_background
    case levelSelector_border
    case ingame_background
    case ingame_pauseButton
    case player1_plannedPath
    case player2_plannedPath
    case player1_snakeBody
    case player2_snakeBody
    case player1_snakeBody_dead
    case player2_snakeBody_dead
    case exitGameButton_fill
    case exitGameButton_text
    case theme1_wall
    case theme1_food
    case theme1_floor
}

extension AppColor {
    var color: Color {
        return Color(self.rawValue)
    }
}
