import XCTest
import Combine
@testable import Legatus

final class JSONDeserrializerTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func testSingleObjectDeserialization() {
        let randomUserJsonDeserializer = JSONDeserializer<RandomUser>.singleObjectDeserializer(keyPath: "user")

        randomUserJsonDeserializer.deserialize(data: JSONDataResponses.singleRandomUserJsonDataResponse)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { randomUser in
                    XCTAssertEqual(randomUser.firstName, "brad")
                    XCTAssertEqual(randomUser.lastName, "gibson")
                    XCTAssertEqual(randomUser.email, "brad.gibson@example.com")
            }
        ).store(in: &subscriptions)
    }

    func testSingleObjectKeyPathSequenceDeserialization() {
        let randomUserJsonDeserializer = JSONDeserializer<Postcode>.singleObjectDeserializer(keyPath: "user", "location")

        randomUserJsonDeserializer.deserialize(data: JSONDataResponses.singleRandomUserJsonDataResponse)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { postcode in
                    XCTAssertEqual(postcode.postcode, "93027")
            }
        ).store(in: &subscriptions)
    }

    func testObjectsArrayDeserialization() {
        let randomUsersJsonDeserializer = JSONDeserializer<RandomUser>.collectionDeserializer(keyPath: "results")

        randomUsersJsonDeserializer.deserialize(data: JSONDataResponses.randomUserJsonDataResponse)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { randomUsers in
                    XCTAssertEqual(randomUsers.first?.firstName, "brad")
                    XCTAssertEqual(randomUsers.first?.lastName, "gibson")
                    XCTAssertEqual(randomUsers.first?.email, "brad.gibson@example.com")

                    XCTAssertEqual(randomUsers.last?.firstName, "Theo")
                    XCTAssertEqual(randomUsers.last?.lastName, "Zhang")
                    XCTAssertEqual(randomUsers.last?.email, "theo.zhang@example.com")
            }
        ).store(in: &subscriptions)
    }

    func testJsonMappingError() {
        let brokenDeserializer = JSONDeserializer<BrokenRandomUser>.collectionDeserializer(keyPath: "results")

        brokenDeserializer.deserialize(data: JSONDataResponses.randomUserJsonDataResponse)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { users in
                    users.forEach {
                        XCTAssertNil($0.firstName)
                        XCTAssertNil($0.lastName)
                    }
            }
        )
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
