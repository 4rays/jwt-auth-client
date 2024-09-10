import Dependencies
import DependenciesMacros
import Foundation
import SimpleKeychain

@DependencyClient
public struct SimpleKeychainClient: Sendable {
  public var keychain: @Sendable () throws -> SimpleKeychain
}

extension DependencyValues {
  public var simpleKeychainClient: SimpleKeychainClient {
    get { self[SimpleKeychainClient.self] }
    set { self[SimpleKeychainClient.self] = newValue }
  }
}

extension SimpleKeychainClient: TestDependencyKey {
  public static let previewValue = Self(
    keychain: { SimpleKeychain() }
  )

  public static let testValue = Self()
}
