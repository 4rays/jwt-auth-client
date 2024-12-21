import Sharing

public enum AuthTokenSession: Equatable, Sendable {
  case missing
  case expired(AuthTokens)
  case valid(AuthTokens)
}

extension AuthTokenSession {
  public var isExpired: Bool {
    switch self {
    case .missing: false
    case .expired: true
    case .valid: false
    }
  }

  public var tokens: AuthTokens? {
    switch self {
    case .missing: nil
    case .expired(let tokens): tokens
    case .valid(let tokens): tokens
    }
  }
}

extension SharedKey where Self == InMemoryKey<AuthTokenSession?>.Default {
  public static var authSession: Self {
    Self[.inMemory("authSession"), default: nil]
  }
}
