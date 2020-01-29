import XCTest
@testable import Legatus

final class ApiClientTests: XCTestCase {

    func testValidGetRequest() {
        let httpBinApiClient = APIClient(baseURL: URL(string: "https://httpbin.org/")!)
        let httpBinGetRequest = HttpBinGetRequest()
        let httpBinGetRequestExpectation = XCTestExpectation(description: "Execute api request.")

        httpBinApiClient.executeRequest(request: httpBinGetRequest) { result in
            if case let .success(httpBinGetResponse) = result {
                XCTAssertEqual(httpBinGetResponse.urlString, "https://httpbin.org/get")
            } else if case let .failure(error) = result{
                XCTAssertTrue(false, "Unexpected response. Error: \(error)")
            }
            httpBinGetRequestExpectation.fulfill()
        }

        wait(for: [httpBinGetRequestExpectation], timeout: 10.0)
    }

    func testValidGetXmlRequest() {
        let httpBinApiClient = APIClient(baseURL: URL(string: "https://httpbin.org/")!)
        let httpBinGetXmlRequest = HttpBinGetXmlRequest()
        let httpBinGetRequestExpectation = XCTestExpectation(description: "Execute api request.")

        let expectedSlidesCount = 2
        httpBinApiClient.executeRequest(request: httpBinGetXmlRequest) { result in
            if case let .success(httpBinSlides) = result {
                XCTAssertFalse(httpBinSlides.isEmpty)
                XCTAssertTrue(httpBinSlides.count == expectedSlidesCount)
            } else if case let .failure(error) = result{
                XCTAssertTrue(false, "Unexpected response. Error: \(error)")
            }
            httpBinGetRequestExpectation.fulfill()
        }

        wait(for: [httpBinGetRequestExpectation], timeout: 10.0)
    }

    func testParallelRequests() {
        let httpBinApiClient = APIClient(baseURL: URL(string: "https://httpbin.org/")!)
        let httpBinGetRequest = HttpBinGetRequest()
        let firstRequestExpectation = XCTestExpectation(description: "Execute first api request.")
        let secondRequestExpectation = XCTestExpectation(description: "Execute second api request.")

        httpBinApiClient.executeRequest(request: httpBinGetRequest) { result in
            if case let .success(httpBinGetResponse) = result {
                XCTAssertEqual(httpBinGetResponse.urlString, "https://httpbin.org/get")
            } else if case let .failure(error) = result{
                XCTAssertTrue(false, "Unexpected response. Error: \(error)")
            }
            firstRequestExpectation.fulfill()
        }

        httpBinApiClient.executeRequest(request: httpBinGetRequest) { result in
            if case let .success(httpBinGetResponse) = result {
                XCTAssertEqual(httpBinGetResponse.urlString, "https://httpbin.org/get")
            } else if case let .failure(error) = result{
                XCTAssertTrue(false, "Unexpected response. Error: \(error)")
            }
            secondRequestExpectation.fulfill()
        }

        wait(for: [firstRequestExpectation, secondRequestExpectation], timeout: 10.0)
    }

    func testRandomUserArrayResponse() {
        let expectedResultsCount = 100
        let randomUserApiClient = APIClient(baseURL: URL(string: "https://randomuser.me/api/")!)
        let randomUserApiRequest = RandomUserApiRequest(results: expectedResultsCount)
        let randomUserApiRequestExpectation = XCTestExpectation(description: "Execute randomuser api request.")

        randomUserApiClient.executeRequest(request: randomUserApiRequest) { result in
            if case let .success(fetchedUsers) = result {
                XCTAssertFalse(fetchedUsers.isEmpty)
                XCTAssertTrue(fetchedUsers.count == expectedResultsCount)
            } else {
                 XCTAssertTrue(false, "Unexpected response.")
            }
            randomUserApiRequestExpectation.fulfill()
        }

         wait(for: [randomUserApiRequestExpectation], timeout: 10.0)
    }

    func testErrorResponse() {
        let apiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
        let randomUserApiRequest = RandomUserApiRequest()
        let apiRequestExpectation = XCTestExpectation(description: "Execute api request.")

        apiClient.executeRequest(request: randomUserApiRequest) { result in
            if case .failure(_) = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false, "Unexpected success response.")
            }
            apiRequestExpectation.fulfill()
        }

        wait(for: [apiRequestExpectation], timeout: 20.0)
    }

    func testAuthRequest() {
        let apiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
        let testAuthRequest = TestAuthRequest()
        testAuthRequest.accessToken = "test_token"
        let apiRequestExpectation = XCTestExpectation(description: "Execute api request.")

        apiClient.executeRequest(request: testAuthRequest) { result in
            if case .failure(_) = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false, "Unexpected success response.")
            }
            apiRequestExpectation.fulfill()
        }

        wait(for: [apiRequestExpectation], timeout: 20.0)
    }

    func testMissedAccessToken() {
        let apiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
        let brokenAuthRequest = TestAuthRequest()
        let apiRequestExpectation = XCTestExpectation(description: "Execute api request.")

        apiClient.executeRequest(request: brokenAuthRequest) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error as? AuthRequestError, AuthRequestError.accessTokenIsNil)
            } else {
                XCTAssertTrue(false, "Unexpected success response.")
            }
            apiRequestExpectation.fulfill()
        }

        wait(for: [apiRequestExpectation], timeout: 5.0)
    }

    func testRequestCancelation() {
        let httpBinApiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
        let httpBinGetRequest = HttpBinGetRequest()
        let httpBinGetRequestExpectation = XCTestExpectation(description: "Execute api request.")

        let cancelationToken = httpBinApiClient.executeRequest(request: httpBinGetRequest) { result in
            if case let .failure(error) = result, let apiClientError = error as? APIClientError {
                XCTAssertTrue(apiClientError == APIClientError.requestCancelled)
            } else if case .success(_) = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false, "Unexpected success response.")
            }
            httpBinGetRequestExpectation.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            cancelationToken?.cancel()
        }

        wait(for: [httpBinGetRequestExpectation], timeout: 10.0)
    }

    func testRequestPublisherCancelation() {
        let httpBinApiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
        let httpBinGetRequest = HttpBinGetRequest()
        let httpBinGetRequestExpectation = XCTestExpectation(description: "Execute api request.")

        let cancelationToken = httpBinApiClient
            .requestPublisher(request: httpBinGetRequest)
            .handleEvents(receiveCancel: {
                XCTAssertTrue(true)
                httpBinGetRequestExpectation.fulfill()
            })
            .sink(receiveCompletion: { _ in
            },
                  receiveValue: { _ in
            })

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            cancelationToken.cancel()
        }

        wait(for: [httpBinGetRequestExpectation], timeout: 10.0)
    }

    func testCancelAllRequests() {
        let httpBinApiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
        let httpBinGetRequest = HttpBinGetRequest()
        let httpBinGetRequestExpectation1 = XCTestExpectation(description: "Execute api request 1.")
        let httpBinGetRequestExpectation2 = XCTestExpectation(description: "Execute randomuser api request 2.")

        httpBinApiClient.executeRequest(request: httpBinGetRequest) { result in
            if case let .failure(error) = result, let apiClientError = error as? APIClientError {
                XCTAssertTrue(apiClientError == APIClientError.requestCancelled)
            } else if case .success(_) = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false, "Unexpected success response.")
            }
            httpBinGetRequestExpectation1.fulfill()
        }

        httpBinApiClient.executeRequest(request: httpBinGetRequest) { result in
            if case let .failure(error) = result, let apiClientError = error as? APIClientError {
                XCTAssertTrue(apiClientError == APIClientError.requestCancelled)
            } else if case .success(_) = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false, "Unexpected success response.")
            }
            httpBinGetRequestExpectation2.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            httpBinApiClient.cancelAllRequests()
        }

        wait(for: [httpBinGetRequestExpectation1, httpBinGetRequestExpectation2], timeout: 10.0)
    }

    static var allTests = [
        ("testValidGetRequest", testValidGetRequest),
        ("testParallelRequests", testParallelRequests),
        ("testValidGetXmlRequest", testValidGetXmlRequest),
        ("testRandomUserArrayResponse", testRandomUserArrayResponse),
        ("testErrorResponse", testErrorResponse),
        ("testAuthRequest", testAuthRequest),
        ("testMissedAccessToken", testMissedAccessToken),
        ("testRequestCancelation", testRequestCancelation),
        ("testRequestPublisherCancelation", testRequestPublisherCancelation),
        ("testCancelAllRequests", testCancelAllRequests)
    ]
}
