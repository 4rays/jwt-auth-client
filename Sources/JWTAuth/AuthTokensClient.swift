import Dependencies
import DependenciesMacros
import Foundation
import Sharing

@DependencyClient
public struct AuthTokensClient: Sendable {
  public var save: @Sendable (AuthTokens) async throws -> Void
  public var destroy: @Sendable () async throws -> Void

  @Sendable public func set(
    _ tokens: AuthTokens?
  ) async throws {
    if let tokens {
      return try await save(tokens)
    } else {
      return try await destroy()
    }
  }
}

extension DependencyValues {
  public var authTokensClient: AuthTokensClient {
    get { self[AuthTokensClient.self] }
    set { self[AuthTokensClient.self] = newValue }
  }
}

extension AuthTokensClient: TestDependencyKey {
  public static let previewValue = Self(
    save: { _ in },
    destroy: {}
  )

  public static let testValue = Self()
}

extension AuthTokensClient: DependencyKey {
  public static let liveValue = { () -> AuthTokensClient in
    @Dependency(\.keychainClient) var keychainClient

    @Sendable
    func persist(_ tokens: AuthTokens?) async throws {
      // Set the tokens in memory cache
      @Shared(.sessionTokens) var sessionTokens
      $sessionTokens.withLock { $0 = tokens }

      // Delete the tokens from the keychain
      try await keychainClient.delete(.accessToken)
      try await keychainClient.delete(.refreshToken)

      // Save the tokens to the keychain
      if let tokens {
        try await keychainClient.save(tokens.access, .accessToken)
        try await keychainClient.save(tokens.refresh, .refreshToken)
      }
    }

    func loadSession() async throws {
      @Shared(.sessionTokens) var sessionTokens
      let tokens = try await keychainClient.loadTokens()
      $sessionTokens.withLock { $0 = tokens }
    }

    // Auto-load the session when the app starts
    Task {
      try await loadSession()
    }

    return Self { token in
      try await persist(token)
    } destroy: {
      try await persist(nil)
    }
  }()
}
