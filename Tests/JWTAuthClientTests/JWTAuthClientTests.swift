import XCTest

@testable import JWTAuthClient

final class JWTAuthClientTests: XCTestCase {
  func testUserSession() throws {
    let tokens = AuthTokens(
      access: "access",
      refresh: "refresh"
    )

    let session = UserSession.signedIn(tokens)

    XCTAssertEqual(session.tokens, tokens)
  }
}
