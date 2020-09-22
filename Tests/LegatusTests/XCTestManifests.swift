import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    [
      testCase(JSONDeserializerTests.allTests),
      testCase(ApiClientTests.allTests),
      testCase(APIReachabilityManagerTests.allTests)
    ]
    .flatMap { $0 }
  }
#endif
