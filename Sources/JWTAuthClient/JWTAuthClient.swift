import Dependencies
import DependenciesMacros
import Foundation
import HTTPRequestBuilder
import HTTPRequestClient

@DependencyClient
public struct JWTAuthClient: Sendable {
  public var refresh: @Sendable (_ refreshToken: String) async throws -> AuthTokens
}

extension DependencyValues {
  public var jwtAuthClient: JWTAuthClient {
    get { self[JWTAuthClient.self] }
    set { self[JWTAuthClient.self] = newValue }
  }
}

extension JWTAuthClient: TestDependencyKey {
  public static let previewValue = Self(
    refresh: { _ in .init(access: "access", refresh: "refresh") }
  )

  public static let testValue = Self()
}

extension JWTAuthClient {
  public func sendJWT<T>(
    _ request: Request,
    baseURL: String,
    retryingAuth: Bool = true,
    decoder: JSONDecoder = .init(),
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60
  ) async throws -> T where T: Decodable {
    @Dependency(\.userSessionClient) var userSessionClient
    @Dependency(\.httpRequestClient) var httpRequestClient

    guard
      let tokens = try await userSessionClient.getTokens()
    else {
      throw Error.missingToken
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
        baseURL: baseURL,
        decoder: decoder,
        urlSession: urlSession,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval
      )
    } catch HTTPRequestClient.Error.badResponse(let id, let code, let body) where code == 401 {
      if retryingAuth {
        let newTokens = try await refresh(tokens.refresh)
        try await userSessionClient.set(.signedIn(newTokens))

        return try await sendJWT(
          request,
          baseURL: baseURL,
          retryingAuth: false,
          decoder: decoder,
          urlSession: urlSession,
          cachePolicy: cachePolicy,
          timeoutInterval: timeoutInterval
        )
      } else {
        throw HTTPRequestClient.Error.badResponse(id, code, body)
      }
    } catch {
      throw error
    }
  }

  public func sendJWT<Success, Failure>(
    _ request: Request,
    baseURL: String,
    retryingAuth: Bool = true,
    urlSession: URLSession = .shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60
  ) async throws -> Result<Success, Failure>
  where
    Success: Decodable,
    Failure: Decodable
  {
    @Dependency(\.userSessionClient) var userSessionClient
    @Dependency(\.httpRequestClient) var httpRequestClient

    guard
      let tokens = try await userSessionClient.getTokens()
    else {
      throw Error.missingToken
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
        baseURL: baseURL,
        urlSession: urlSession,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval
      )
    } catch HTTPRequestClient.Error.badResponse(let id, let code, let body) where code == 401 {
      if retryingAuth {
        let newTokens = try await refresh(tokens.refresh)
        try await userSessionClient.set(.signedIn(newTokens))

        return try await sendJWT(
          request,
          baseURL: baseURL,
          retryingAuth: false,
          urlSession: urlSession,
          cachePolicy: cachePolicy,
          timeoutInterval: timeoutInterval
        )
      } else {
        throw HTTPRequestClient.Error.badResponse(id, code, body)
      }
    } catch {
      throw error
    }
  }
}

extension JWTAuthClient {
  public enum Error: Swift.Error {
    case missingToken
  }
}
