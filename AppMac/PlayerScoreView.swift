// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

struct PlayerScoreView: View {
    @Binding var playerLength: UInt

    var body: some View {
        Text("\(self.playerLength)")
            .font(.custom("Iceland", size: 70))
            .bold()
            .fixedSize(horizontal: true, vertical: true)
            .foregroundColor(.black)
            .frame(width: 100, height: 100)
            .background(MyGradient())
            .background(Color.yellow.opacity(0.7))
            .aspectRatio(1.0, contentMode: .fit)
    }
}

struct MyGradient: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.1), Color.green.opacity(0.1)]), startPoint: UnitPoint(x: 0, y: 0), endPoint: UnitPoint(x: 1, y: 1))
    }
}

struct PlayerScoreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlayerScoreView(playerLength: .constant(123))
                .previewLayout(.fixed(width: 100, height: 100))
            PlayerScoreView(playerLength: .constant(123))
                .previewLayout(.fixed(width: 80, height: 150))
            PlayerScoreView(playerLength: .constant(123))
                .previewLayout(.fixed(width: 150, height: 80))
        }
    }
}
