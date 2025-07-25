import Sharing

/// Represents the current authentication session state.
///
/// `AuthSession` encapsulates the different states an authentication session can be in,
/// providing a type-safe way to handle authentication state throughout your application.
///
/// ## Overview
///
/// The session can be in one of three states:
/// - `.missing`: No authentication tokens are present
/// - `.expired`: Tokens are present but the access token has expired
/// - `.valid`: Tokens are present and the access token is still valid
///
/// ## Usage
///
/// ```swift
/// @Shared(.authSession) var session
/// 
/// switch session {
/// case .missing:
///     // Show login screen
///     break
/// case .expired(let tokens):
///     // Attempt to refresh tokens
///     break
/// case .valid(let tokens):
///     // User is authenticated, proceed with app
///     break
/// }
/// ```
public enum AuthSession: Equatable, Sendable {
  /// No authentication tokens are present in the session.
  case missing
  
  /// Authentication tokens are present but the access token has expired.
  ///
  /// - Parameter tokens: The expired authentication tokens
  case expired(AuthTokens)
  
  /// Authentication tokens are present and the access token is still valid.
  ///
  /// - Parameter tokens: The valid authentication tokens
  case valid(AuthTokens)
}

extension AuthSession {
  /// Indicates whether the session is in an expired state.
  ///
  /// - Returns: `true` if the session is `.expired`, `false` otherwise
  ///
  /// ## Usage
  ///
  /// ```swift
  /// @Shared(.authSession) var session
  /// 
  /// if session?.isExpired == true {
  ///     // Refresh tokens or redirect to login
  /// }
  /// ```
  public var isExpired: Bool {
    switch self {
    case .missing: false
    case .expired: true
    case .valid: false
    }
  }

  /// The authentication tokens associated with this session, if any.
  ///
  /// - Returns: The `AuthTokens` for `.expired` and `.valid` cases, `nil` for `.missing`
  ///
  /// ## Usage
  ///
  /// ```swift
  /// @Shared(.authSession) var session
  /// 
  /// if let tokens = session?.tokens {
  ///     // Use tokens for authenticated requests
  /// }
  /// ```
  public var tokens: AuthTokens? {
    switch self {
    case .missing: nil
    case .expired(let tokens): tokens
    case .valid(let tokens): tokens
    }
  }
}

extension SharedKey where Self == InMemoryKey<AuthSession?>.Default {
  /// A shared key for accessing the current authentication session across the application.
  ///
  /// This key provides access to the in-memory authentication session state that is
  /// shared across your application using the Sharing library.
  ///
  /// ## Usage
  ///
  /// ```swift
  /// @Shared(.authSession) var session: AuthSession?
  /// 
  /// // Update session
  /// session = .valid(tokens)
  /// 
  /// // Check session state
  /// switch session {
  /// case .some(.valid):
  ///     // User is authenticated
  /// case .some(.expired):
  ///     // Tokens need refresh
  /// case .some(.missing), .none:
  ///     // Show login
  /// }
  /// ```
  public static var authSession: Self {
    Self[.inMemory("authSession"), default: nil]
  }
}
