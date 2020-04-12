// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import Combine
import SwiftUI

public class MyModel: ObservableObject {
    @Published public var jumpToLevelSelector: Bool = false
}
