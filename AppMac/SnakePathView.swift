// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftUI

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

struct SnakePathView: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 200, y: 100))
            path.addLine(to: CGPoint(x: 100, y: 300))
            path.addLine(to: CGPoint(x: 300, y: 300))
            path.addLine(to: CGPoint(x: 200, y: 100))
        }
        .fill(Color.black)
        .frame(width: 400, height: 400)
    }
}

struct SnakePathView_Previews: PreviewProvider {
    static var previews: some View {
        SnakePathView()
    }
}
