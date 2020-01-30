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
                    XCTAssertEqual(randomUser.firstName, "brad")
                    XCTAssertEqual(randomUser.lastName, "gibson")
                    XCTAssertEqual(randomUser.email, "brad.gibson@example.com")
            }).store(in: &subscriptions)
    }

    func testSingleObjectKeyPathSequenceDeserialization() {
        let randomUserJsonDeserializer = JSONDeserializer<Postcode>.singleObjectDeserializer(keyPath: "user", "location", "postcode")

        randomUserJsonDeserializer.deserialize(data: JSONDataResponses.singleRandomUserJsonDataResponse)
            .sink(receiveCompletion: { _ in
            },
                  receiveValue: { postcode in
                    XCTAssertEqual(postcode.value, "93027")
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

    override func tearDown() {
        subscriptions.removeAll()

        super.tearDown()
    }

    static var allTests = [
        ("testSingleObjectDeserialization", testSingleObjectDeserialization),
        ("testSingleObjectKeyPathSequenceDeserialization", testSingleObjectKeyPathSequenceDeserialization),
        ("testObjectsArrayDeserialization", testObjectsArrayDeserialization),
        ("testJsonMappingError", testJsonMappingError)
    ]
}
