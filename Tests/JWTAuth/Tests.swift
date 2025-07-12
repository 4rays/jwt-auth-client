import Dependencies
import Foundation
import Sharing
import Testing

@testable import JWTAuth

@Test func loadSession() async throws {
  let client = JWTAuthClient(
    baseURL: { "https://api.example.com" },
    refresh: { _ in .init(access: "accessToken", refresh: "accessToken") }
  )

  try await withDependencies {
    $0.keychainClient = .init(
      save: { _, _ in },
      load: { _ in "accessToken" },
      delete: { _ in },
      reset: {}
    )

    $0.jwtAuthClient = client
  } operation: {
    @Shared(.authSession) var authSession
    #expect(authSession == nil)

    try await client.loadSession()
    #expect(authSession == .expired(.init(access: "accessToken", refresh: "accessToken")))
  }
}

@Test func skipLoadingExistingSession() async throws {
  let client = JWTAuthClient(
    baseURL: { "https://api.example.com" },
    refresh: { _ in .init(access: "accessToken", refresh: "accessToken") }
  )

  try await withDependencies {
    $0.jwtAuthClient = client
  } operation: {
    @Shared(.authSession) var authSession
    $authSession.withLock {
      $0 = .expired(.init(access: "accessToken", refresh: "accessToken"))
    }

    try await client.loadSession()
    #expect(authSession == .expired(.init(access: "accessToken", refresh: "accessToken")))
  }
}

// MARK: - AuthTokens Tests

@Test func authTokensInitialization() {
  let tokens = AuthTokens(access: "access123", refresh: "refresh456")
  #expect(tokens.access == "access123")
  #expect(tokens.refresh == "refresh456")
}

@Test func authTokensEquality() {
  let tokens1 = AuthTokens(access: "access", refresh: "refresh")
  let tokens2 = AuthTokens(access: "access", refresh: "refresh")
  let tokens3 = AuthTokens(access: "different", refresh: "refresh")
  
  #expect(tokens1 == tokens2)
  #expect(tokens1 != tokens3)
}

@Test func authTokensHashable() {
  let tokens1 = AuthTokens(access: "access", refresh: "refresh")
  let tokens2 = AuthTokens(access: "access", refresh: "refresh")
  
  #expect(tokens1.hashValue == tokens2.hashValue)
}

@Test func authTokensToJWTWithInvalidToken() {
  let tokens = AuthTokens(access: "invalid-jwt", refresh: "refresh")
  
  #expect(throws: (any Error).self) {
    try tokens.toJWT()
  }
}

@Test func authTokensIsExpiredWithInvalidToken() {
  let tokens = AuthTokens(access: "invalid-jwt", refresh: "refresh")
  #expect(tokens.isExpired == true)
}

@Test func authTokensToSessionWithInvalidToken() {
  let tokens = AuthTokens(access: "invalid-jwt", refresh: "refresh")
  let session = tokens.toSession()
  #expect(session == .expired(tokens))
}

@Test func authTokensSubscriptWithInvalidToken() {
  let tokens = AuthTokens(access: "invalid-jwt", refresh: "refresh")
  
  #expect(tokens[string: "sub"] == nil)
  #expect(tokens[boolean: "admin"] == nil)
  #expect(tokens[int: "exp"] == nil)
  #expect(tokens[double: "score"] == nil)
  #expect(tokens[date: "iat"] == nil)
  #expect(tokens[strings: "roles"] == nil)
}

// MARK: - AuthTokens.Error Tests

@Test func authTokensErrorDescriptions() {
  #expect(AuthTokens.Error.missingToken.errorDescription == "The token seems to be missing.")
  #expect(AuthTokens.Error.invalidToken.errorDescription == "The token is invalid.")
  #expect(AuthTokens.Error.expiredToken.errorDescription == "The token is expired.")
}

@Test func authTokensErrorTitle() {
  #expect(AuthTokens.Error.missingToken.title == "Session Error")
  #expect(AuthTokens.Error.invalidToken.title == "Session Error")
  #expect(AuthTokens.Error.expiredToken.title == "Session Error")
}

@Test func authTokensErrorEquality() {
  #expect(AuthTokens.Error.missingToken == AuthTokens.Error.missingToken)
  #expect(AuthTokens.Error.invalidToken == AuthTokens.Error.invalidToken)
  #expect(AuthTokens.Error.expiredToken == AuthTokens.Error.expiredToken)
  #expect(AuthTokens.Error.missingToken != AuthTokens.Error.invalidToken)
}

// MARK: - AuthSession Tests

@Test func authSessionIsExpiredProperty() {
  let tokens = AuthTokens(access: "access", refresh: "refresh")
  
  #expect(AuthSession.missing.isExpired == false)
  #expect(AuthSession.expired(tokens).isExpired == true)
  #expect(AuthSession.valid(tokens).isExpired == false)
}

@Test func authSessionTokensProperty() {
  let tokens = AuthTokens(access: "access", refresh: "refresh")
  
  #expect(AuthSession.missing.tokens == nil)
  #expect(AuthSession.expired(tokens).tokens == tokens)
  #expect(AuthSession.valid(tokens).tokens == tokens)
}

@Test func authSessionEquality() {
  let tokens1 = AuthTokens(access: "access1", refresh: "refresh1")
  let tokens2 = AuthTokens(access: "access2", refresh: "refresh2")
  
  #expect(AuthSession.missing == AuthSession.missing)
  #expect(AuthSession.expired(tokens1) == AuthSession.expired(tokens1))
  #expect(AuthSession.valid(tokens1) == AuthSession.valid(tokens1))
  
  #expect(AuthSession.missing != AuthSession.expired(tokens1))
  #expect(AuthSession.expired(tokens1) != AuthSession.valid(tokens1))
  #expect(AuthSession.expired(tokens1) != AuthSession.expired(tokens2))
  #expect(AuthSession.valid(tokens1) != AuthSession.valid(tokens2))
}
