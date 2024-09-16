# JWTAuth

A dependency client that handles JWT auth in apps using the Swift Composable Architecture (TCA).

## Usage

Before using any clients, provide an instance of `SimpleKeychain` via a `liveValue` of the `SimpleKeychainClient` dependency in your app:

```swift
extension SimpleKeychainClient: DependencyKey {
  static let liveValue = Self {
    // Your keychain logic here
  } baseURL: {
    "https://my-base-url.com"
  }
}
```

### JWT Auth

Start by defining a `liveValue` of the `JWTAuthClient` in your app:

```swift
extension JWTAuthClient: DependencyKey {
  static let liveValue = Self(
    refresh: { token in
      // Your refresh logic here
    }
  )
}
```

Once defined, you can use the following methods:

```swift
public func sendWithAuth<T>(...) async throws -> T where T: Decodable

public func sendWithAuth<Success, Failure>(...) async throws -> Result<Success, Failure>
where Success: Decodable, Failure: Decodable
```

The `autoTokenRefresh` parameter is used to determine if the client should retry the request if the token is expired.
If set to `false`, the client forwards the server error if the token is expired.

### User Session

The `UserSessionClient` is a client that handles the user session via one of the following methods:

```swift
public var save: @Sendable (AuthTokens) async throws -> UserSession
public var load: @Sendable () async throws -> UserSession
public var destroy: @Sendable () async throws -> UserSession
```

### Keychain Client

The `KeychainClient` is a client that handles the keychain via one of the following methods:

```swift
public var save: @Sendable (_ value: String, _ as: Keys) async throws -> Void
public var load: @Sendable (_ key: Keys) async -> String?
public var delete: @Sendable (_ key: Keys) async -> Void
public var reset: @Sendable () async -> Void
```
