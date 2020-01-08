import XCTest
import Combine
@testable import Legatus

final class JSONDeserrializerTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func testSingleObjectDeserialization() {
        let randomUserJsonDeserializer = JSONDeserializer<RandomUser>.singleObjectDeserializer(keyPath: "user")

        randomUserJsonDeserializer.deserialize(data: JSONDataResponses.singleRandomUserJsonDataResponse)
            .sink(receiveCompletion: { _ in
            },
                  receiveValue: { randomUser in
                    XCTAssertEqual(randomUser.firstName,"brad")
                    XCTAssertEqual(randomUser.lastName, "gibson")
                    XCTAssertEqual(randomUser.email, "brad.gibson@example.com")
            }).store(in: &subscriptions)
    }

    func testObjectsArrayDeserialization() {
        let randomUsersJsonDeserializer = JSONDeserializer<RandomUser>.objectsArrayDeserializer(keyPath: "results")

        randomUsersJsonDeserializer.deserialize(data: JSONDataResponses.randomUserJsonDataResponse)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { randomUsers in
                    XCTAssertEqual(randomUsers.first?.firstName, "brad")
                    XCTAssertEqual(randomUsers.first?.lastName, "gibson")
                    XCTAssertEqual(randomUsers.first?.email, "brad.gibson@example.com")

                    XCTAssertEqual(randomUsers.last?.firstName, "Theo")
                    XCTAssertEqual(randomUsers.last?.lastName, "Zhang")
                    XCTAssertEqual(randomUsers.last?.email, "theo.zhang@example.com")
            }).store(in: &subscriptions)
    }

    func testJsonMappingError() {
        let brokenDeserializer = JSONDeserializer<BrokenRandomUser>.objectsArrayDeserializer(keyPath: "results")

        brokenDeserializer.deserialize(data: JSONDataResponses.randomUserJsonDataResponse)
            .sink(receiveCompletion: { completion in
                guard case let .failure(error) = completion  else { return }
                let jsonDeserializerError = error as? JSONDeserializerError
                XCTAssertNotNil(jsonDeserializerError)
            },
                  receiveValue: { users in
                    XCTAssertTrue(users.isEmpty)
            })
            .store(in: &subscriptions)
    }

    func testErrorDeserialization() {
        let responseErrorDeserializer = JSONDeserializer<ResponseError>.singleObjectDeserializer()

        responseErrorDeserializer.deserialize(data: JSONDataResponses.errorJsonDataResponse)
            .sink(receiveCompletion: { completion in
                guard case let .failure(error) = completion  else {
                    XCTAssertTrue(true)
                    return
                }
                XCTAssertTrue(false, "Received unexpected error: \(error). Check init?(json: JSON).")
            },
                  receiveValue: { reponseError in
                    XCTAssertTrue(reponseError.errorCode == .invalidResponse)
                    XCTAssertEqual(reponseError.message, "Test error message.")
            })
            .store(in: &subscriptions)
    }

    func testErrorWithKeypathDeserialization() {
        let responseErrorDeserializer = JSONDeserializer<ResponseError>.singleObjectDeserializer(keyPath: "error")

        responseErrorDeserializer.deserialize(data: JSONDataResponses.errorKeyPathJsonDataResponse)
            .sink(receiveCompletion: { completion in
                guard case let .failure(error) = completion  else {
                    XCTAssertTrue(true)
                    return
                }
                XCTAssertTrue(false, "Received unexpected error: \(error). Check init?(json: JSON).")
            },
                  receiveValue: { reponseError in
                    XCTAssertTrue(reponseError.errorCode == .invalidResponse)
                    XCTAssertEqual(reponseError.message, "Test error message.")
            })
            .store(in: &subscriptions)
    }

    override func tearDown() {
        subscriptions.removeAll()
        
        super.tearDown()
    }

    static var allTests = [
        ("testSingleObjectDeserialization", testSingleObjectDeserialization),
        ("testObjectsArrayDeserialization", testObjectsArrayDeserialization),
        ("testJsonMappingError", testJsonMappingError),
        ("testErrorDeserialization", testErrorDeserialization),
        ("testErrorWithKeypathDeserialization", testErrorWithKeypathDeserialization)
    ]
}
