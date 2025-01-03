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
  /// Load session into memory
  public func loadSession() async throws {
    @Shared(.authSession) var session
    @Dependency(\.keychainClient) var keychainClient

    guard
      session == nil
    else { return }

    let tokens = try await keychainClient.loadTokens()
    $session.withLock { $0 = tokens?.toSession() }
  }

  /// Refreshes the tokens and persists them.
  public func refreshExpiredTokens() async throws {
    @Dependency(\.authTokensClient) var authTokensClient
    @Shared(.authSession) var session

    try await loadSession()

    guard
      let tokens = session?.tokens
    else {
      throw AuthTokens.Error.missingToken
    }

    do {
      try tokens.validateAccessToken()
    } catch {
      do {
        let newTokens = try await refresh(tokens)
        try await authTokensClient.set(newTokens)
      } catch {
        try await authTokensClient.destroy()
      }
    }
  }

  /// Sends an HTTP request and returns a successful response.
  ///
  /// - Parameters:
  ///   - request: The request to send.
  ///   - decoder: The JSON decoder to use for decoding the response.
  ///   - urlSession: The URL session to use for sending the request.
  ///   - cachePolicy: The cache policy to use for the request.
  ///   - timeoutInterval: The timeout interval for the request.
  ///   - middleware: The middleware to apply to the request.
  /// - Returns: A successful response containing the decoded data.
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

  /// Sends an authenticated HTTP request and returns a successful response.
  ///
  /// - Parameters:
  ///   - request: The request to send.
  ///   - refreshExpiredToken: Whether to refresh the access token if it has expired.
  ///   - decoder: The JSON decoder to use for decoding the response.
  ///   - urlSession: The URL session to use for sending the request.
  ///   - cachePolicy: The cache policy to use for the request.
  ///   - timeoutInterval: The timeout interval for the request.
  ///   - middleware: The middleware to apply to the request.
  /// - Returns: A successful response containing the decoded data.
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
    @Shared(.authSession) var session

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

    if refreshExpiredToken {
      try await refreshExpiredTokens()
    }

    guard
      let sessionTokens = session?.tokens
    else {
      throw AuthTokens.Error.missingToken
    }

    return try await sendRequest(with: sessionTokens.access)
  }

  /// Sends an HTTP request and returns a response with a success or error value.
  ///
  /// - Parameters:
  ///   - request: The request to send.
  ///   - decoder: The JSON decoder to use for decoding the response.
  ///   - urlSession: The URL session to use for sending the request.
  ///   - cachePolicy: The cache policy to use for the request.
  ///   - timeoutInterval: The timeout interval for the request.
  ///   - middleware: The middleware to apply to the request.
  /// - Returns: A response containing either the decoded success data or the decoded error data.
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

  /// Sends an authenticated HTTP request and returns a response with a success or error value.
  ///
  /// - Parameters:
  ///   - request: The request to send.
  ///   - decoder: The JSON decoder to use for decoding the response.
  ///   - refreshExpiredToken: Whether to refresh the access token if it has expired.
  ///   - urlSession: The URL session to use for sending the request.
  ///   - cachePolicy: The cache policy to use for the request.
  ///   - timeoutInterval: The timeout interval for the request.
  ///   - middleware: The middleware to apply to the request.
  /// - Returns: A response containing either the decoded success data or the decoded error data.
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
    @Shared(.authSession) var session

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

    if refreshExpiredToken {
      try await refreshExpiredTokens()
    }

    guard
      let sessionTokens = session?.tokens
    else {
      throw AuthTokens.Error.missingToken
    }

    return try await sendRequest(with: sessionTokens.access)
  }
}
