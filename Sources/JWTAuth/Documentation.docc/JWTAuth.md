# `JWTAuth`

A dependency client that handles JWT authentication in Swift apps using The Composable Architecture (TCA).

## Overview

This library handles authentication token storage, automatic refresh, session management, and bearer-token authenticated HTTP requests.

### Key Features

- **Automatic Token Refresh**: Seamlessly refreshes expired tokens behind the scenes
- **Secure Storage**: Uses iOS/macOS keychain for secure token persistence
- **Session Management**: Shared session state across your entire application

### Core Components

The library consists of several key components that work together:

- `JWTAuthClient` - Main client for authentication and HTTP requests
- `AuthTokens` - Container for access and refresh tokens with validation
- `AuthSession` - Represents the current authentication state
- `AuthTokensClient` - Manages token persistence and memory caching
- `KeychainClient` - Provides secure keychain storage operations

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

- `JWTAuthClient`

### Token Management

- `AuthTokens`
- `AuthSession`
- `AuthTokensClient`

### Storage

- `KeychainClient`
- `KeychainError`

### Dependencies

- `DependencyValues`
