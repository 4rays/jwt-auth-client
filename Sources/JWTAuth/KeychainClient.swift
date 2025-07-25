import Dependencies
import DependenciesMacros
import Foundation

/// A client for secure keychain storage operations.
///
/// `KeychainClient` provides a type-safe interface for storing, retrieving, and managing
/// sensitive data in the iOS/macOS keychain. It's designed specifically for authentication
/// tokens but can be extended for other sensitive data.
///
/// ## Overview
///
/// The client provides:
/// - Secure storage of access and refresh tokens
/// - Type-safe key management
/// - Convenient token loading operations
/// - Keychain cleanup and reset functionality
///
/// ## Usage
///
/// ```swift
/// @Dependency(\.keychainClient) var keychainClient
/// 
/// // Save tokens
/// try await keychainClient.save("access_token", .accessToken)
/// try await keychainClient.save("refresh_token", .refreshToken)
/// 
/// // Load tokens
/// let tokens = try await keychainClient.loadTokens()
/// 
/// // Clean up
/// try await keychainClient.reset()
/// ```
@DependencyClient
public struct KeychainClient: Sendable {
  /// Saves a string value to the keychain with the specified key.
  ///
  /// If an item with the same key already exists, it will be replaced.
  ///
  /// - Parameters:
  ///   - value: The string value to store
  ///   - key: The keychain key to associate with the value
  /// - Throws: A `KeychainError` if the save operation fails
  public var save: @Sendable (_ value: String, _ as: Keys) async throws -> Void
  
  /// Loads a string value from the keychain for the specified key.
  ///
  /// - Parameter key: The keychain key to retrieve
  /// - Returns: The stored string value, or `nil` if no value exists for the key
  /// - Throws: A `KeychainError` if the load operation fails
  public var load: @Sendable (_ key: Keys) async throws -> String?
  
  /// Deletes the keychain item for the specified key.
  ///
  /// This operation is safe to call even if no item exists for the key.
  ///
  /// - Parameter key: The keychain key to delete
  /// - Throws: A `KeychainError` if the delete operation fails
  public var delete: @Sendable (_ key: Keys) async throws -> Void
  
  /// Removes all items from the keychain.
  ///
  /// Use this method with caution as it will delete all keychain items,
  /// not just authentication tokens.
  ///
  /// - Throws: A `KeychainError` if the reset operation fails
  public var reset: @Sendable () async throws -> Void

  /// Type-safe keys for keychain storage.
  ///
  /// This structure provides predefined keys for common authentication tokens
  /// and ensures type safety when accessing keychain items.
  public struct Keys: Hashable, Sendable {
    /// The underlying keychain key string.
    public let value: String
    
    /// Key for storing the JWT access token.
    public static let accessToken: KeychainClient.Keys = Self(value: "accessToken")
    
    /// Key for storing the JWT refresh token.
    public static let refreshToken = Self(value: "refreshToken")
  }
}

/// Errors that can occur during keychain operations.
public enum KeychainError: LocalizedError, Equatable {
  /// An error occurred while saving data to the keychain.
  ///
  /// - Parameter message: A detailed description of the failure
  case savingFailed(message: String)
  
  /// An error occurred while loading data from the keychain.
  ///
  /// - Parameter message: A detailed description of the failure
  case loadingFailed(message: String)

  /// A localized message describing what error occurred.
  public var errorDescription: String? {
    switch self {
    case .savingFailed(let message):
      return "Saving to keychain failed. Reason: \(message)"

    case .loadingFailed(let message):
      return "Loading from keychain failed. Reason: \(message)"
    }
  }
}

extension DependencyValues {
  public var keychainClient: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}

extension KeychainClient {
  /// Loads both access and refresh tokens from the keychain and creates an `AuthTokens` instance.
  ///
  /// This convenience method retrieves both tokens and returns them as a single
  /// `AuthTokens` object, or `nil` if either token is missing.
  ///
  /// - Returns: An `AuthTokens` instance if both tokens exist, `nil` otherwise
  /// - Throws: A `KeychainError` if the keychain operations fail
  ///
  /// ## Usage
  ///
  /// ```swift
  /// @Dependency(\.keychainClient) var keychainClient
  /// 
  /// if let tokens = try await keychainClient.loadTokens() {
  ///     // Both tokens are available
  ///     let session = tokens.toSession()
  /// } else {
  ///     // One or both tokens are missing
  ///     // Redirect to login
  /// }
  /// ```
  public func loadTokens() async throws -> AuthTokens? {
    let accessToken = try await load(.accessToken)
    let refreshToken = try await load(.refreshToken)

    guard
      let refreshToken,
      let accessToken
    else {
      return nil
    }

    return AuthTokens(
      access: accessToken,
      refresh: refreshToken
    )
  }
}

extension KeychainClient: TestDependencyKey {
  public static let previewValue = Self(
    save: { _, _ in },
    load: { _ in nil },
    delete: { _ in },
    reset: {}
  )

  public static let testValue = Self()
}

extension KeychainClient: DependencyKey {
  public static let liveValue = { () -> Self in
    @Dependency(\.simpleKeychain) var keychain

    return Self { value, key in
      if try keychain.hasItem(forKey: key.value) {
        try keychain.deleteItem(forKey: key.value)
      }

      try keychain.set(value, forKey: key.value)
    } load: { key in
      try? keychain.string(forKey: key.value)
    } delete: { key in
      if try keychain.hasItem(forKey: key.value) {
        try keychain.deleteItem(forKey: key.value)
      }
    } reset: {
      try? keychain.deleteAll()
    }
  }()
}
