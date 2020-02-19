// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

struct PlayerScoreView: View {
    @Binding var playerLength: UInt

    var body: some View {
        Text("\(playerLength)")
            .font(.custom("Iceland", size: 80))
    }
}

struct PlayerScoreView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerScoreView(playerLength: .constant(123))
    }
}
