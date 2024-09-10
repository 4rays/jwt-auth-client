import Foundation

public enum UserSession: Hashable, Sendable {
  case signedOut
  case signedIn(AuthTokens)

  public var tokens: AuthTokens? {
    switch self {
    case .signedOut: nil
    case .signedIn(let tokens): tokens
    }
  }

  public var isSignedIn: Bool {
    self != .signedOut
  }
}
