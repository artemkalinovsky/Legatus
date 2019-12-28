import XCTest
import Combine
@testable import Legatus

final class JSONDeserrializerTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func testSingleObjectDeserialization() {
        let randomUserJsonDeserializer = JSONDeserializer<RandomUser>.singleObjectDeserializer(keyPath: "user")
        let randomUserJsonData = JSONDataResponses.singleRandomUserJsonDataResponse

        randomUserJsonDeserializer.deserialize(randomUserJsonData)
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
        let randomUsersJsonData = JSONDataResponses.randomUserJsonDataResponse

        randomUsersJsonDeserializer.deserialize(randomUsersJsonData)
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

    static var allTests = [
        ("testSingleObjectDeserialization", testSingleObjectDeserialization),
        ("testObjectsArrayDeserialization", testObjectsArrayDeserialization)
    ]
}
