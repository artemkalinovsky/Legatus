import XCTest
import BoltsSwift
@testable import Legatus

final class JSONDeserrializerTests: XCTestCase {

    func testSingleObjectDeserialization() {
        let jsonDeserializerExpectation = XCTestExpectation(description: "Execute json deserialization.")

        let randomUserJsonDeserializer = JSONDeserializer<RandomUser>.singleObjectDeserializer(keyPath: "user")
        let randomUserJsonData = JSONDataResponses.singleRandomUserJsonDataResponse

        randomUserJsonDeserializer.deserialize(randomUserJsonData).continueWith { task in
            XCTAssertEqual(task.result?.firstName, "brad")
            XCTAssertEqual(task.result?.lastName, "gibson")
            XCTAssertEqual(task.result?.email, "brad.gibson@example.com")

            jsonDeserializerExpectation.fulfill()
        }

        wait(for: [jsonDeserializerExpectation], timeout: 10.0)
    }

    func testObjectsArrayDeserialization() {
        let jsonDeserializerExpectation = XCTestExpectation(description: "Execute json deserialization.")

        let randomUsersJsonDeserializer = JSONDeserializer<RandomUser>.objectsArrayDeserializer(keyPath: "results")
        let randomUsersJsonData = JSONDataResponses.randomUserJsonDataResponse

        randomUsersJsonDeserializer.deserialize(randomUsersJsonData).continueWith { task in
            XCTAssertEqual(task.result?.first?.firstName, "brad")
            XCTAssertEqual(task.result?.first?.lastName, "gibson")
            XCTAssertEqual(task.result?.first?.email, "brad.gibson@example.com")

            XCTAssertEqual(task.result?.last?.firstName, "Theo")
            XCTAssertEqual(task.result?.last?.lastName, "Zhang")
            XCTAssertEqual(task.result?.last?.email, "theo.zhang@example.com")

            jsonDeserializerExpectation.fulfill()
        }

        wait(for: [jsonDeserializerExpectation], timeout: 10.0)
    }

    static var allTests = [
        ("testSingleObjectDeserialization", testSingleObjectDeserialization),
        ("testObjectsArrayDeserialization", testObjectsArrayDeserialization)
    ]
}
