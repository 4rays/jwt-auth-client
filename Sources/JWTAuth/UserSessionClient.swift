import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct UserSessionClient: Sendable {
  public var save: @Sendable (AuthTokens) async throws -> UserSession
  public var load: @Sendable () async throws -> UserSession
  public var destroy: @Sendable () async throws -> UserSession

  public init(
    save: @Sendable @escaping (AuthTokens) async throws -> UserSession,
    load: @Sendable @escaping () async throws -> UserSession,
    destroy: @Sendable @escaping () async throws -> UserSession
  ) {
    self.save = save
    self.load = load
    self.destroy = destroy
  }

  @discardableResult
  @Sendable public func set(
    _ session: UserSession
  ) async throws -> UserSession {
    if let token = session.tokens {
      return try await save(token)
    } else {
      return try await destroy()
    }
  }

  @Sendable public func getTokens() async throws -> AuthTokens? {
    try await load().tokens
  }
}

extension DependencyValues {
  public var userSessionClient: UserSessionClient {
    get { self[UserSessionClient.self] }
    set { self[UserSessionClient.self] = newValue }
  }
}

extension UserSessionClient: TestDependencyKey {
  public static let previewValue = Self(
    save: { _ in .signedOut },
    load: { .signedOut },
    destroy: { .signedOut }
  )

  public static let testValue = Self()
}

extension UserSessionClient: DependencyKey {
  public static let liveValue = { () -> UserSessionClient in
    @Dependency(\.keychainClient) var keychainClient

    @Sendable
    func persist(_ session: UserSession) async throws -> UserSession {
      if let token = session.tokens {
        try await keychainClient.save(token.access, .accessToken)
        try await keychainClient.save(token.refresh, .refreshToken)
      } else {
        await keychainClient.delete(.accessToken)
        await keychainClient.delete(.refreshToken)
      }

      return session
    }

    return Self { token in
      let session = UserSession.signedIn(token)
      return try await persist(session)
    } load: {
      try await keychainClient.loadSession()
    } destroy: {
      return try await persist(.signedOut)
    }
  }()
}
