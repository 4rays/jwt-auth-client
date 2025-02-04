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
