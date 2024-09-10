// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JWTAuthClient",
  platforms: [
    .macOS(.v12),
    .iOS(.v16),
    .watchOS(.v8),
    .tvOS(.v16),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "JWTAuthClient",
      targets: ["JWTAuthClient"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.3.9"),
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.1.0"),
    .package(url: "https://github.com/auth0/SimpleKeychain", from: "1.1.0"),
    .package(url: "https://github.com/4rays/http-request-client", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "JWTAuthClient",
      dependencies: [
        .product(name: "JWTDecode", package: "JWTDecode.swift"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "SimpleKeychain", package: "SimpleKeychain"),
        .product(name: "HTTPRequestClient", package: "http-request-client"),
      ]
    ),
    .testTarget(
      name: "JWTAuthClientTests",
      dependencies: ["JWTAuthClient"]
    ),
  ]
)
