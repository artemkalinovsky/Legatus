import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(JSONDeserializerTests.allTests),
        testCase(ApiClientTests.allTests),
        testCase(APIReachabilityManagerTests.allTests)
        ].flatMap { $0 }
}
#endif
