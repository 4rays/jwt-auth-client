import Sharing

public enum AuthSession: Equatable, Sendable {
  case missing
  case expired(AuthTokens)
  case valid(AuthTokens)
}

extension AuthSession {
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

extension SharedKey where Self == InMemoryKey<AuthSession?>.Default {
  public static var authSession: Self {
    Self[.inMemory("authSession"), default: nil]
  }
}
