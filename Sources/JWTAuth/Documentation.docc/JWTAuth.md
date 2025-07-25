# ``JWTAuth``

A dependency client that handles JWT authentication in apps using the Swift Composable Architecture (TCA).

## Overview

JWT Auth Client provides a comprehensive solution for managing JWT authentication in Swift applications built with The Composable Architecture. It handles token storage, automatic refresh, session management, and authenticated HTTP requests.

### Key Features

- **Automatic Token Refresh**: Seamlessly refreshes expired tokens behind the scenes
- **Secure Storage**: Uses iOS/macOS keychain for secure token persistence
- **Session Management**: Shared session state across your entire application
- **TCA Integration**: Built specifically for The Composable Architecture
- **Type Safety**: Comprehensive Swift type system usage with proper error handling
- **Testing Support**: Full mocking capabilities for reliable testing

### Core Components

The library consists of several key components that work together:

- ``JWTAuthClient`` - Main client for authentication and HTTP requests
- ``AuthTokens`` - Container for access and refresh tokens with validation
- ``AuthSession`` - Represents the current authentication state
- ``AuthTokensClient`` - Manages token persistence and memory caching
- ``KeychainClient`` - Provides secure keychain storage operations

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:AuthenticationFlow>

### Core Concepts

- <doc:TokenManagement>
- <doc:ErrorHandling>

### Testing and Advanced Usage

- <doc:Testing>
- <doc:AdvancedUsage>

### Main Client

- ``JWTAuthClient``

### Token Management

- ``AuthTokens``
- ``AuthSession``
- ``AuthTokensClient``

### Storage

- ``KeychainClient``
- ``KeychainError``

### Dependencies

- ``DependencyValues``