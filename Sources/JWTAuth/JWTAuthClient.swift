import Dependencies
import DependenciesMacros
import Foundation
import HTTPRequestBuilder
import HTTPRequestClient

@DependencyClient
public struct JWTAuthClient: Sendable {
  public var refresh: @Sendable (_ refreshToken: String) async throws -> AuthTokens
  public var baseURL: @Sendable () throws -> String
}

extension DependencyValues {
  public var jwtAuthClient: JWTAuthClient {
    get { self[JWTAuthClient.self] }
    set { self[JWTAuthClient.self] = newValue }
  }
}

extension JWTAuthClient: TestDependencyKey {
  public static let previewValue = Self(
    refresh: { _ in .init(access: "access", refresh: "refresh") },
    baseURL: { "" }
  )

  public static let testValue = Self()
}

extension JWTAuthClient {
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

  public func sendWithAuth<T>(
    _ request: Request = .init(),
    autoTokenRefresh: Bool = true,
    decoder: JSONDecoder = .init(),
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> SuccessResponse<T> where T: Decodable {
    @Dependency(\.userSessionClient) var userSessionClient
    @Dependency(\.httpRequestClient) var httpRequestClient

    guard
      let tokens = try await userSessionClient.getTokens()
    else {
      throw AuthTokens.Error.missingToken
    }

    do {
      try tokens.validate()
    } catch {
      try await userSessionClient.set(.signedOut)
      throw error
    }

    let bearerRequest = try bearerAuth(tokens.access)(request)

    do {
      return try await httpRequestClient.send(
        bearerRequest,
        baseURL: try baseURL(),
        decoder: decoder,
        urlSession: urlSession,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval,
        middleware: middleware
      )
    } catch HTTPRequestClient.Error.badResponse(let id, let code, let body) where code == 401 {
      if autoTokenRefresh {
        let newTokens = try await refresh(tokens.refresh)
        try await userSessionClient.set(.signedIn(newTokens))

        return try await sendWithAuth(
          request,
          autoTokenRefresh: false,
          decoder: decoder,
          urlSession: urlSession,
          cachePolicy: cachePolicy,
          timeoutInterval: timeoutInterval,
          middleware: middleware
        )
      } else {
        throw HTTPRequestClient.Error.badResponse(id, code, body)
      }
    } catch {
      throw error
    }
  }

  public func send<T, ServerError>(
    _ request: Request = .init(),
    autoTokenRefresh: Bool = true,
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
      baseURL: try baseURL(),
      urlSession: urlSession,
      cachePolicy: cachePolicy,
      timeoutInterval: timeoutInterval,
      middleware: middleware
    )
  }

  public func sendWithAuth<T, ServerError>(
    _ request: Request = .init(),
    autoTokenRefresh: Bool = true,
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> Response<T, ServerError>
  where
    T: Decodable,
    ServerError: Decodable
  {
    @Dependency(\.userSessionClient) var userSessionClient
    @Dependency(\.httpRequestClient) var httpRequestClient

    guard
      let tokens = try await userSessionClient.getTokens()
    else {
      throw AuthTokens.Error.missingToken
    }

    do {
      try tokens.validate()
    } catch {
      try await userSessionClient.set(.signedOut)
      throw error
    }

    let bearerRequest = try bearerAuth(tokens.access)(request)

    do {
      return try await httpRequestClient.send(
        bearerRequest,
        baseURL: try baseURL(),
        urlSession: urlSession,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval,
        middleware: middleware
      )
    } catch HTTPRequestClient.Error.badResponse(let id, let code, let body) where code == 401 {
      if autoTokenRefresh {
        let newTokens = try await refresh(tokens.refresh)
        try await userSessionClient.set(.signedIn(newTokens))

        return try await sendWithAuth(
          request,
          autoTokenRefresh: false,
          urlSession: urlSession,
          cachePolicy: cachePolicy,
          timeoutInterval: timeoutInterval,
          middleware: middleware
        )
      } else {
        throw HTTPRequestClient.Error.badResponse(id, code, body)
      }
    } catch {
      throw error
    }
  }
}
