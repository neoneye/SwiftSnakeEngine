// DO NOT EDIT.
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: SnakeGameStateModel.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

/// Regenerate swift file
/// PROMPT> protoc --swift_out=. SnakeGameStateModel.proto

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that your are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct SnakeGameStateModelPosition {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The coordinate system origin is in the left/bottom corner.
  var x: UInt32 = 0

  var y: UInt32 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct SnakeGameStateModelPlayer {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var headDirection: SnakeGameStateModelPlayer.HeadDirection = .up

  var bodyPositions: [SnakeGameStateModelPosition] = []

  var action: SnakeGameStateModelPlayer.Action = .die

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum HeadDirection: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case up // = 0
    case left // = 1
    case right // = 2
    case down // = 3
    case UNRECOGNIZED(Int)

    init() {
      self = .up
    }

    init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .up
      case 1: self = .left
      case 2: self = .right
      case 3: self = .down
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    var rawValue: Int {
      switch self {
      case .up: return 0
      case .left: return 1
      case .right: return 2
      case .down: return 3
      case .UNRECOGNIZED(let i): return i
      }
    }

  }

  enum Action: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case die // = 0
    case moveForward // = 1
    case moveCw // = 2
    case moveCcw // = 3
    case UNRECOGNIZED(Int)

    init() {
      self = .die
    }

    init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .die
      case 1: self = .moveForward
      case 2: self = .moveCw
      case 3: self = .moveCcw
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    var rawValue: Int {
      switch self {
      case .die: return 0
      case .moveForward: return 1
      case .moveCw: return 2
      case .moveCcw: return 3
      case .UNRECOGNIZED(let i): return i
      }
    }

  }

  init() {}
}

#if swift(>=4.2)

extension SnakeGameStateModelPlayer.HeadDirection: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static var allCases: [SnakeGameStateModelPlayer.HeadDirection] = [
    .up,
    .left,
    .right,
    .down,
  ]
}

extension SnakeGameStateModelPlayer.Action: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static var allCases: [SnakeGameStateModelPlayer.Action] = [
    .die,
    .moveForward,
    .moveCw,
    .moveCcw,
  ]
}

#endif  // swift(>=4.2)

struct SnakeGameStateModelLevel {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The level has a size: width * height.
  var levelWidth: UInt32 = 0

  var levelHeight: UInt32 = 0

  /// Places where the snake can go.
  var emptyPositions: [SnakeGameStateModelPosition] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct SnakeGameStateIngameModel {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var level: SnakeGameStateModelLevel {
    get {return _storage._level ?? SnakeGameStateModelLevel()}
    set {_uniqueStorage()._level = newValue}
  }
  /// Returns true if `level` has been explicitly set.
  var hasLevel: Bool {return _storage._level != nil}
  /// Clears the value of `level`. Subsequent reads from it will return its default value.
  mutating func clearLevel() {_uniqueStorage()._level = nil}

  /// There may be food or there may be no food.
  var optionalFoodPosition: OneOf_OptionalFoodPosition? {
    get {return _storage._optionalFoodPosition}
    set {_uniqueStorage()._optionalFoodPosition = newValue}
  }

  var foodPosition: SnakeGameStateModelPosition {
    get {
      if case .foodPosition(let v)? = _storage._optionalFoodPosition {return v}
      return SnakeGameStateModelPosition()
    }
    set {_uniqueStorage()._optionalFoodPosition = .foodPosition(newValue)}
  }

  /// While ingame it's uncertain which of the players becomes the winner or the looser.
  var optionalPlayerA: OneOf_OptionalPlayerA? {
    get {return _storage._optionalPlayerA}
    set {_uniqueStorage()._optionalPlayerA = newValue}
  }

  var playerA: SnakeGameStateModelPlayer {
    get {
      if case .playerA(let v)? = _storage._optionalPlayerA {return v}
      return SnakeGameStateModelPlayer()
    }
    set {_uniqueStorage()._optionalPlayerA = .playerA(newValue)}
  }

  var optionalPlayerB: OneOf_OptionalPlayerB? {
    get {return _storage._optionalPlayerB}
    set {_uniqueStorage()._optionalPlayerB = newValue}
  }

  var playerB: SnakeGameStateModelPlayer {
    get {
      if case .playerB(let v)? = _storage._optionalPlayerB {return v}
      return SnakeGameStateModelPlayer()
    }
    set {_uniqueStorage()._optionalPlayerB = .playerB(newValue)}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  /// There may be food or there may be no food.
  enum OneOf_OptionalFoodPosition: Equatable {
    case foodPosition(SnakeGameStateModelPosition)

  #if !swift(>=4.1)
    static func ==(lhs: SnakeGameStateIngameModel.OneOf_OptionalFoodPosition, rhs: SnakeGameStateIngameModel.OneOf_OptionalFoodPosition) -> Bool {
      switch (lhs, rhs) {
      case (.foodPosition(let l), .foodPosition(let r)): return l == r
      }
    }
  #endif
  }

  /// While ingame it's uncertain which of the players becomes the winner or the looser.
  enum OneOf_OptionalPlayerA: Equatable {
    case playerA(SnakeGameStateModelPlayer)

  #if !swift(>=4.1)
    static func ==(lhs: SnakeGameStateIngameModel.OneOf_OptionalPlayerA, rhs: SnakeGameStateIngameModel.OneOf_OptionalPlayerA) -> Bool {
      switch (lhs, rhs) {
      case (.playerA(let l), .playerA(let r)): return l == r
      }
    }
  #endif
  }

  enum OneOf_OptionalPlayerB: Equatable {
    case playerB(SnakeGameStateModelPlayer)

  #if !swift(>=4.1)
    static func ==(lhs: SnakeGameStateIngameModel.OneOf_OptionalPlayerB, rhs: SnakeGameStateIngameModel.OneOf_OptionalPlayerB) -> Bool {
      switch (lhs, rhs) {
      case (.playerB(let l), .playerB(let r)): return l == r
      }
    }
  #endif
  }

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

struct SnakeGameStateWinnerLooserModelStep {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// There may be food or there may be no food.
  var optionalFoodPosition: OneOf_OptionalFoodPosition? {
    get {return _storage._optionalFoodPosition}
    set {_uniqueStorage()._optionalFoodPosition = newValue}
  }

  var foodPosition: SnakeGameStateModelPosition {
    get {
      if case .foodPosition(let v)? = _storage._optionalFoodPosition {return v}
      return SnakeGameStateModelPosition()
    }
    set {_uniqueStorage()._optionalFoodPosition = .foodPosition(newValue)}
  }

  /// There is always the player A (the winner).
  var playerA: SnakeGameStateModelPlayer {
    get {return _storage._playerA ?? SnakeGameStateModelPlayer()}
    set {_uniqueStorage()._playerA = newValue}
  }
  /// Returns true if `playerA` has been explicitly set.
  var hasPlayerA: Bool {return _storage._playerA != nil}
  /// Clears the value of `playerA`. Subsequent reads from it will return its default value.
  mutating func clearPlayerA() {_uniqueStorage()._playerA = nil}

  /// There may be an opponent player B (the looser).
  var optionalPlayerB: OneOf_OptionalPlayerB? {
    get {return _storage._optionalPlayerB}
    set {_uniqueStorage()._optionalPlayerB = newValue}
  }

  var playerB: SnakeGameStateModelPlayer {
    get {
      if case .playerB(let v)? = _storage._optionalPlayerB {return v}
      return SnakeGameStateModelPlayer()
    }
    set {_uniqueStorage()._optionalPlayerB = .playerB(newValue)}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  /// There may be food or there may be no food.
  enum OneOf_OptionalFoodPosition: Equatable {
    case foodPosition(SnakeGameStateModelPosition)

  #if !swift(>=4.1)
    static func ==(lhs: SnakeGameStateWinnerLooserModelStep.OneOf_OptionalFoodPosition, rhs: SnakeGameStateWinnerLooserModelStep.OneOf_OptionalFoodPosition) -> Bool {
      switch (lhs, rhs) {
      case (.foodPosition(let l), .foodPosition(let r)): return l == r
      }
    }
  #endif
  }

  /// There may be an opponent player B (the looser).
  enum OneOf_OptionalPlayerB: Equatable {
    case playerB(SnakeGameStateModelPlayer)

  #if !swift(>=4.1)
    static func ==(lhs: SnakeGameStateWinnerLooserModelStep.OneOf_OptionalPlayerB, rhs: SnakeGameStateWinnerLooserModelStep.OneOf_OptionalPlayerB) -> Bool {
      switch (lhs, rhs) {
      case (.playerB(let l), .playerB(let r)): return l == r
      }
    }
  #endif
  }

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

struct SnakeGameStateWinnerLooserModel {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var level: SnakeGameStateModelLevel {
    get {return _storage._level ?? SnakeGameStateModelLevel()}
    set {_uniqueStorage()._level = newValue}
  }
  /// Returns true if `level` has been explicitly set.
  var hasLevel: Bool {return _storage._level != nil}
  /// Clears the value of `level`. Subsequent reads from it will return its default value.
  mutating func clearLevel() {_uniqueStorage()._level = nil}

  var steps: [SnakeGameStateWinnerLooserModelStep] {
    get {return _storage._steps}
    set {_uniqueStorage()._steps = newValue}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension SnakeGameStateModelPosition: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "SnakeGameStateModelPosition"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "x"),
    2: .same(proto: "y"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularUInt32Field(value: &self.x)
      case 2: try decoder.decodeSingularUInt32Field(value: &self.y)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.x != 0 {
      try visitor.visitSingularUInt32Field(value: self.x, fieldNumber: 1)
    }
    if self.y != 0 {
      try visitor.visitSingularUInt32Field(value: self.y, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SnakeGameStateModelPosition, rhs: SnakeGameStateModelPosition) -> Bool {
    if lhs.x != rhs.x {return false}
    if lhs.y != rhs.y {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SnakeGameStateModelPlayer: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "SnakeGameStateModelPlayer"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "head_direction"),
    2: .standard(proto: "body_positions"),
    3: .same(proto: "action"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularEnumField(value: &self.headDirection)
      case 2: try decoder.decodeRepeatedMessageField(value: &self.bodyPositions)
      case 3: try decoder.decodeSingularEnumField(value: &self.action)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.headDirection != .up {
      try visitor.visitSingularEnumField(value: self.headDirection, fieldNumber: 1)
    }
    if !self.bodyPositions.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.bodyPositions, fieldNumber: 2)
    }
    if self.action != .die {
      try visitor.visitSingularEnumField(value: self.action, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SnakeGameStateModelPlayer, rhs: SnakeGameStateModelPlayer) -> Bool {
    if lhs.headDirection != rhs.headDirection {return false}
    if lhs.bodyPositions != rhs.bodyPositions {return false}
    if lhs.action != rhs.action {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SnakeGameStateModelPlayer.HeadDirection: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "UP"),
    1: .same(proto: "LEFT"),
    2: .same(proto: "RIGHT"),
    3: .same(proto: "DOWN"),
  ]
}

extension SnakeGameStateModelPlayer.Action: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "DIE"),
    1: .same(proto: "MOVE_FORWARD"),
    2: .same(proto: "MOVE_CW"),
    3: .same(proto: "MOVE_CCW"),
  ]
}

extension SnakeGameStateModelLevel: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "SnakeGameStateModelLevel"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "level_width"),
    2: .standard(proto: "level_height"),
    3: .standard(proto: "empty_positions"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularUInt32Field(value: &self.levelWidth)
      case 2: try decoder.decodeSingularUInt32Field(value: &self.levelHeight)
      case 3: try decoder.decodeRepeatedMessageField(value: &self.emptyPositions)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.levelWidth != 0 {
      try visitor.visitSingularUInt32Field(value: self.levelWidth, fieldNumber: 1)
    }
    if self.levelHeight != 0 {
      try visitor.visitSingularUInt32Field(value: self.levelHeight, fieldNumber: 2)
    }
    if !self.emptyPositions.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.emptyPositions, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SnakeGameStateModelLevel, rhs: SnakeGameStateModelLevel) -> Bool {
    if lhs.levelWidth != rhs.levelWidth {return false}
    if lhs.levelHeight != rhs.levelHeight {return false}
    if lhs.emptyPositions != rhs.emptyPositions {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SnakeGameStateIngameModel: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "SnakeGameStateIngameModel"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "level"),
    2: .standard(proto: "food_position"),
    3: .standard(proto: "player_a"),
    4: .standard(proto: "player_b"),
  ]

  fileprivate class _StorageClass {
    var _level: SnakeGameStateModelLevel? = nil
    var _optionalFoodPosition: SnakeGameStateIngameModel.OneOf_OptionalFoodPosition?
    var _optionalPlayerA: SnakeGameStateIngameModel.OneOf_OptionalPlayerA?
    var _optionalPlayerB: SnakeGameStateIngameModel.OneOf_OptionalPlayerB?

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _level = source._level
      _optionalFoodPosition = source._optionalFoodPosition
      _optionalPlayerA = source._optionalPlayerA
      _optionalPlayerB = source._optionalPlayerB
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularMessageField(value: &_storage._level)
        case 2:
          var v: SnakeGameStateModelPosition?
          if let current = _storage._optionalFoodPosition {
            try decoder.handleConflictingOneOf()
            if case .foodPosition(let m) = current {v = m}
          }
          try decoder.decodeSingularMessageField(value: &v)
          if let v = v {_storage._optionalFoodPosition = .foodPosition(v)}
        case 3:
          var v: SnakeGameStateModelPlayer?
          if let current = _storage._optionalPlayerA {
            try decoder.handleConflictingOneOf()
            if case .playerA(let m) = current {v = m}
          }
          try decoder.decodeSingularMessageField(value: &v)
          if let v = v {_storage._optionalPlayerA = .playerA(v)}
        case 4:
          var v: SnakeGameStateModelPlayer?
          if let current = _storage._optionalPlayerB {
            try decoder.handleConflictingOneOf()
            if case .playerB(let m) = current {v = m}
          }
          try decoder.decodeSingularMessageField(value: &v)
          if let v = v {_storage._optionalPlayerB = .playerB(v)}
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._level {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      }
      if case .foodPosition(let v)? = _storage._optionalFoodPosition {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      }
      if case .playerA(let v)? = _storage._optionalPlayerA {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
      }
      if case .playerB(let v)? = _storage._optionalPlayerB {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SnakeGameStateIngameModel, rhs: SnakeGameStateIngameModel) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._level != rhs_storage._level {return false}
        if _storage._optionalFoodPosition != rhs_storage._optionalFoodPosition {return false}
        if _storage._optionalPlayerA != rhs_storage._optionalPlayerA {return false}
        if _storage._optionalPlayerB != rhs_storage._optionalPlayerB {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SnakeGameStateWinnerLooserModelStep: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "SnakeGameStateWinnerLooserModelStep"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "food_position"),
    2: .standard(proto: "player_a"),
    3: .standard(proto: "player_b"),
  ]

  fileprivate class _StorageClass {
    var _optionalFoodPosition: SnakeGameStateWinnerLooserModelStep.OneOf_OptionalFoodPosition?
    var _playerA: SnakeGameStateModelPlayer? = nil
    var _optionalPlayerB: SnakeGameStateWinnerLooserModelStep.OneOf_OptionalPlayerB?

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _optionalFoodPosition = source._optionalFoodPosition
      _playerA = source._playerA
      _optionalPlayerB = source._optionalPlayerB
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1:
          var v: SnakeGameStateModelPosition?
          if let current = _storage._optionalFoodPosition {
            try decoder.handleConflictingOneOf()
            if case .foodPosition(let m) = current {v = m}
          }
          try decoder.decodeSingularMessageField(value: &v)
          if let v = v {_storage._optionalFoodPosition = .foodPosition(v)}
        case 2: try decoder.decodeSingularMessageField(value: &_storage._playerA)
        case 3:
          var v: SnakeGameStateModelPlayer?
          if let current = _storage._optionalPlayerB {
            try decoder.handleConflictingOneOf()
            if case .playerB(let m) = current {v = m}
          }
          try decoder.decodeSingularMessageField(value: &v)
          if let v = v {_storage._optionalPlayerB = .playerB(v)}
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if case .foodPosition(let v)? = _storage._optionalFoodPosition {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      }
      if let v = _storage._playerA {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      }
      if case .playerB(let v)? = _storage._optionalPlayerB {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SnakeGameStateWinnerLooserModelStep, rhs: SnakeGameStateWinnerLooserModelStep) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._optionalFoodPosition != rhs_storage._optionalFoodPosition {return false}
        if _storage._playerA != rhs_storage._playerA {return false}
        if _storage._optionalPlayerB != rhs_storage._optionalPlayerB {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SnakeGameStateWinnerLooserModel: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "SnakeGameStateWinnerLooserModel"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "level"),
    2: .same(proto: "steps"),
  ]

  fileprivate class _StorageClass {
    var _level: SnakeGameStateModelLevel? = nil
    var _steps: [SnakeGameStateWinnerLooserModelStep] = []

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _level = source._level
      _steps = source._steps
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularMessageField(value: &_storage._level)
        case 2: try decoder.decodeRepeatedMessageField(value: &_storage._steps)
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._level {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      }
      if !_storage._steps.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._steps, fieldNumber: 2)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SnakeGameStateWinnerLooserModel, rhs: SnakeGameStateWinnerLooserModel) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._level != rhs_storage._level {return false}
        if _storage._steps != rhs_storage._steps {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
