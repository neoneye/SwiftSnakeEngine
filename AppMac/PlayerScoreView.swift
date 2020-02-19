// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

struct PlayerScoreView: View {
    @Binding var playerLength: UInt
    var color: Color

    var body: some View {
        Text("\(self.playerLength)")
            .font(.custom("Iceland", size: 70))
            .fixedSize(horizontal: true, vertical: true)
            .foregroundColor(.black)
            .frame(width: 100, height: 100)
            .background(self.color)
            .aspectRatio(1.0, contentMode: .fit)
    }
}

struct PlayerScoreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlayerScoreView(playerLength: .constant(123), color: .blue)
            PlayerScoreView(playerLength: .constant(123), color: .green)
        }
    }
}
