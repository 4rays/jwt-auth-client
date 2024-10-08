import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct KeychainClient: Sendable {
  public var save: @Sendable (_ value: String, _ as: Keys) async throws -> Void
  public var load: @Sendable (_ key: Keys) async throws -> String?
  public var delete: @Sendable (_ key: Keys) async throws -> Void
  public var reset: @Sendable () async throws -> Void

  public struct Keys: Hashable, Sendable {
    public let value: String
    public static let accessToken: KeychainClient.Keys = Self(value: "accessToken")
    public static let refreshToken = Self(value: "refreshToken")
  }
}

public enum KeychainError: LocalizedError, Equatable {
  case savingFailed(message: String)
  case loadingFailed(message: String)

  public var errorDescription: String? {
    switch self {
    case .savingFailed(let message):
      return "Saving to keychain failed. Reason: \(message)"

    case .loadingFailed(let message):
      return "Loading from keychain failed. Reason: \(message)"
    }
  }
}

extension DependencyValues {
  public var keychainClient: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}

extension KeychainClient {
  public func loadSession() async throws -> UserSession {
    let accessToken = try await load(.accessToken)
    let refreshToken = try await load(.refreshToken)

    guard
      let refreshToken,
      let accessToken
    else {
      return .signedOut
    }

    let tokens = AuthTokens(
      access: accessToken,
      refresh: refreshToken
    )

    return .signedIn(tokens)
  }
}

extension KeychainClient: TestDependencyKey {
  public static let previewValue = Self(
    save: { _, _ in },
    load: { _ in nil },
    delete: { _ in },
    reset: {}
  )

  public static let testValue = Self()
}

extension KeychainClient: DependencyKey {
  public static let liveValue = { () -> Self in
    @Dependency(\.simpleKeychainClient.keychain) var keychain

    return Self { value, key in
      if try keychain().hasItem(forKey: key.value) {
        try keychain().deleteItem(forKey: key.value)
      }

      try keychain().set(value, forKey: key.value)
    } load: { key in
      try? keychain().string(forKey: key.value)
    } delete: { key in
      if try keychain().hasItem(forKey: key.value) {
        try keychain().deleteItem(forKey: key.value)
      }
    } reset: {
      try? keychain().deleteAll()
    }
  }()
}
