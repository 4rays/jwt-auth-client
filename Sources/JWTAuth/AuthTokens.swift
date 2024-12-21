import Foundation
import JWTDecode
import Sharing

public struct AuthTokens: Codable, Hashable, Sendable {
  public var access: String
  public var refresh: String

  public init(
    access: String,
    refresh: String
  ) {
    self.access = access
    self.refresh = refresh
  }
}

extension AuthTokens {
  public enum Error: LocalizedError {
    case missingToken
    case invalidToken
    case expiredToken

    public var errorDescription: String? {
      switch self {
      case .missingToken: "The token seems to be missing."
      case .invalidToken: "The token is invalid."
      case .expiredToken: "The token is expired."
      }
    }

    public var title: String {
      return "Session Error"
    }
  }

  public func toJWT() throws -> JWT {
    try decode(jwt: self.access)
  }

  public var isExpired: Bool {
    do {
      return try validateAccessToken().expired
    } catch {
      return true
    }
  }

  @discardableResult
  func validateAccessToken() throws -> JWT {
    let jwt = try toJWT()

    if jwt.expired {
      throw Error.expiredToken
    }

    return jwt
  }

  public subscript(string claim: String) -> String? {
    try? toJWT().claim(name: claim).string
  }

  public subscript(boolean claim: String) -> Bool? {
    try? toJWT().claim(name: claim).boolean
  }

  public subscript(int claim: String) -> Int? {
    try? toJWT().claim(name: claim).integer
  }

  public subscript(double claim: String) -> Double? {
    try? toJWT().claim(name: claim).double
  }

  public subscript(date claim: String) -> Date? {
    try? toJWT().claim(name: claim).date
  }

  public subscript(strings claim: String) -> [String]? {
    try? toJWT().claim(name: claim).array
  }

  public func toSession() -> AuthSession {
    guard !isExpired
    else { return .expired(self) }
    return .valid(self)
  }
}
