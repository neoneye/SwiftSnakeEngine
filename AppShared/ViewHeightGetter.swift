// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SwiftUI

struct ViewHeightPreferenceKey: PreferenceKey {
    typealias Value = CGFloat

    static var defaultValue: Value = 0

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct ViewHeightGetter: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ViewHeightPreferenceKey.self,
                    value: proxy.size.height
                )
            }
        )
    }
}
