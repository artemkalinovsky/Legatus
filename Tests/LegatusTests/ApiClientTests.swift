import XCTest
@testable import Legatus

final class ApiClientTests: XCTestCase {

    func testNotEmptyResponse() {
        let randomUserApiClient = APIClient(baseURL: URL(string: "https://randomuser.me/api/")!)
        let randomUserApiRequest = RandomUserApiRequest()
        let randomUserApiExpectation = XCTestExpectation(description: "Execute randomuser api request.")

        randomUserApiClient.executeRequest(request: randomUserApiRequest) { result in
            if case let .success(fetchedUsers) = result {
                XCTAssertFalse(fetchedUsers.isEmpty)
                XCTAssertTrue(fetchedUsers.count == 1)
                XCTAssertNotNil(fetchedUsers.first?.firstName)
                XCTAssertNotNil(fetchedUsers.first?.lastName)
                XCTAssertNotNil(fetchedUsers.first?.email)
            }
            randomUserApiExpectation.fulfill()
        }

        wait(for: [randomUserApiExpectation], timeout: 10.0)
    }

    func testErrorResponse() {
        let apiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
        let randomUserApiRequest = RandomUserApiRequest()
        let apiRequestExpectation = XCTestExpectation(description: "Execute api request.")

        apiClient.executeRequest(request: randomUserApiRequest) { result in
            if case .failure(_) = result {
                XCTAssertTrue(true)
            }
            apiRequestExpectation.fulfill()
        }

        wait(for: [apiRequestExpectation], timeout: 10.0)
    }

    static var allTests = [
        ("testNotEmptyResponse", testNotEmptyResponse),
        ("testErrorResponse", testErrorResponse)
    ]
}
