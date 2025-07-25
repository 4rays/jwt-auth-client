# 🪻 jwt-auth-client

A dependency client that handles JWT auth in apps using the Swift Composable Architecture (TCA).
It is part of the [Indigo Stack](https://indigostack.org).

## SimpleKeychain

The library uses the default keychain via the `SimpleKeychain` library.
If you want to use a different keychain, you can achieve that via `prepareDependencies`, for instance in the initializer of your `App`.

```swift
init() {
  prepareDependencies {
    $0.simpleKeychain = SimpleKeychain(...)
  }
}
```

### JWT Auth

A `liveValue` of the `JWTAuthClient` is required.

```swift
extension JWTAuthClient: @retroactive DependencyKey {
  static let liveValue = Self(
    baseURL: {
      // Your base URL here
    },
    refresh: { token in
      // Your refresh logic here
    }
  )
}
```

Once defined, you can use the following methods:

```swift
public func sendAuthenticated<T>(...) async throws -> T where T: Decodable

public func sendAuthenticated<Success, Failure>(...) async throws -> Result<Success, Failure>
where Success: Decodable, Failure: Decodable
```

The `refreshExpiredToken` parameter is used to determine if the client should retry the request if the token is expired.
If set to `false`, the client forwards the server error if the token is expired.

### Auth Tokens Client

The `AuthTokensClient` is a client that handles the auth tokens via one of the following methods:

```swift
public var save: @Sendable (AuthTokens) async throws -> Void
public var load: @Sendable () async throws -> AuthTokens?
public var destroy: @Sendable () async throws -> Void
```

You can access the current cached session using the `@Shared(.sessionTokens)` macro.

> [!NOTE]
> Unless you call the `refreshExpiredTokens` method on the `JWTAuthClient`,
> you need to manually call the `load` method of `AuthTokensClient` to load the tokens.

### Keychain Client

The `KeychainClient` is a client that handles the keychain via one of the following methods:

```swift
public var save: @Sendable (_ value: String, _ as: Keys) async throws -> Void
public var load: @Sendable (_ key: Keys) async -> String?
public var delete: @Sendable (_ key: Keys) async -> Void
public var reset: @Sendable () async -> Void
```

## Documentation

This project uses [Swift-DocC](https://github.com/swiftlang/swift-docc-plugin) for documentation generation.

### Viewing Documentation Online

The latest documentation is automatically built and deployed [on GitHub Pages](https://indigo-ce.github.io/jwt-auth-client/)

### Building Documentation Locally

To generate static documentation:

```bash
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target JWTAuth --output-path ./docs \
    --transform-for-static-hosting --hosting-base-path jwt-auth-client
```

### Previewing Documentation Locally

To preview documentation with a local web server:

```bash
swift package --disable-sandbox preview-documentation --target JWTAuth
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
