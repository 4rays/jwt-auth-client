import Dependencies
import DependenciesMacros
import Foundation
import HTTPRequestBuilder
import HTTPRequestClient
import Sharing

@DependencyClient
public struct JWTAuthClient: Sendable {
  public var baseURL: @Sendable () throws -> String
  public var refresh: @Sendable (_ authTokens: AuthTokens) async throws -> AuthTokens
}

extension DependencyValues {
  public var jwtAuthClient: JWTAuthClient {
    get { self[JWTAuthClient.self] }
    set { self[JWTAuthClient.self] = newValue }
  }
}

extension JWTAuthClient: TestDependencyKey {
  public static let previewValue = Self(
    baseURL: { "" },
    refresh: { _ in .init(access: "access", refresh: "refresh") }
  )

  public static let testValue = Self()
}

extension JWTAuthClient {
  /// Refreshes the tokens and persists them.
  public func refreshExpiredTokens() async throws {
    @Dependency(\.authTokensClient) var authTokensClient
    @Shared(.sessionTokens) var oldTokens

    guard
      let oldTokens
    else {
      throw AuthTokens.Error.missingToken
    }

    do {
      try oldTokens.validateAccessToken()
    } catch {
      let newTokens = try await refresh(oldTokens)
      try await authTokensClient.set(newTokens)
    }
  }

  public func send<T>(
    _ request: Request = .init(),
    decoder: JSONDecoder = .init(),
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> SuccessResponse<T> where T: Decodable {
    @Dependency(\.httpRequestClient) var httpRequestClient

    return try await httpRequestClient.send(
      request,
      baseURL: try baseURL(),
      decoder: decoder,
      urlSession: urlSession,
      cachePolicy: cachePolicy,
      timeoutInterval: timeoutInterval,
      middleware: middleware
    )
  }

  public func sendAuthenticated<T>(
    _ request: Request = .init(),
    refreshExpiredToken: Bool = true,
    decoder: JSONDecoder = .init(),
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> SuccessResponse<T> where T: Decodable {
    @Dependency(\.authTokensClient) var authTokensClient
    @Dependency(\.httpRequestClient) var httpRequestClient
    @Shared(.sessionTokens) var sessionTokens

    func sendRequest(with accessToken: String) async throws -> SuccessResponse<T> {
      let bearerRequest = try bearerAuth(accessToken)(request)

      return try await httpRequestClient.send(
        bearerRequest,
        baseURL: try baseURL(),
        decoder: decoder,
        urlSession: urlSession,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval,
        middleware: middleware
      )
    }

    guard
      let sessionTokens
    else {
      throw AuthTokens.Error.missingToken
    }

    if refreshExpiredToken {
      do {
        try sessionTokens.validateAccessToken()
        return try await sendRequest(with: sessionTokens.access)
      } catch {
        let newTokens = try await refresh(sessionTokens)
        try await authTokensClient.set(newTokens)
        return try await sendRequest(with: newTokens.access)
      }
    } else {
      return try await sendRequest(with: sessionTokens.access)
    }
  }

  public func send<T, ServerError>(
    _ request: Request = .init(),
    decoder: JSONDecoder = .init(),
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> Response<T, ServerError>
  where
    T: Decodable,
    ServerError: Decodable
  {
    @Dependency(\.httpRequestClient) var httpRequestClient

    return try await httpRequestClient.send(
      request,
      decoder: decoder,
      baseURL: try baseURL(),
      urlSession: urlSession,
      cachePolicy: cachePolicy,
      timeoutInterval: timeoutInterval,
      middleware: middleware
    )
  }

  public func sendAuthenticated<T, ServerError>(
    _ request: Request = .init(),
    decoder: JSONDecoder = .init(),
    refreshExpiredToken: Bool = true,
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> Response<T, ServerError>
  where
    T: Decodable,
    ServerError: Decodable
  {
    @Dependency(\.authTokensClient) var authTokensClient
    @Dependency(\.httpRequestClient) var httpRequestClient
    @Shared(.sessionTokens) var sessionTokens

    func sendRequest(with accessToken: String) async throws -> Response<T, ServerError> {
      let bearerRequest = try bearerAuth(accessToken)(request)

      return try await httpRequestClient.send(
        bearerRequest,
        decoder: decoder,
        baseURL: try baseURL(),
        urlSession: urlSession,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval,
        middleware: middleware
      )
    }

    guard
      let sessionTokens
    else {
      throw AuthTokens.Error.missingToken
    }

    if refreshExpiredToken {
      do {
        try sessionTokens.validateAccessToken()
        return try await sendRequest(with: sessionTokens.access)
      } catch {
        let newTokens = try await refresh(sessionTokens)
        try await authTokensClient.set(newTokens)
        return try await sendRequest(with: newTokens.access)
      }
    } else {
      return try await sendRequest(with: sessionTokens.access)
    }
  }
}
