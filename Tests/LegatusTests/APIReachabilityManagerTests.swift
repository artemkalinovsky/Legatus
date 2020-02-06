import XCTest
import Combine
@testable import Legatus

final class APIReachabilityManagerTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()

    func testReachabilityManagerInitialState() {
        XCTAssertFalse(APIReachabilityManager.shared.isStarted)
        XCTAssertFalse(APIReachabilityManager.shared.isReachable)
        APIReachabilityManager.shared.start(for: URL(string: "https://www.apple.com")!)
        XCTAssertTrue(APIReachabilityManager.shared.isStarted)
        XCTAssertTrue(APIReachabilityManager.shared.isReachable)
    }

    static var allTests = [
        ("testReachabilityManagerInitialState", testReachabilityManagerInitialState)
    ]
}
