import Dependencies
import DependenciesMacros
import Foundation
@preconcurrency import SimpleKeychain

extension SimpleKeychain: @unchecked @retroactive Sendable {}

extension DependencyValues {
  public var simpleKeychain: SimpleKeychain {
    get { self[SimpleKeychainKey.self] }
    set { self[SimpleKeychainKey.self] = newValue }
  }

  private enum SimpleKeychainKey: DependencyKey {
    public static let liveValue = SimpleKeychain()
  }

  static var testValue: SimpleKeychain {
    SimpleKeychain()
  }
}
