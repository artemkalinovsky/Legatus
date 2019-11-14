import XCTest
@testable import Legatus

final class LegatusTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Legatus().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
