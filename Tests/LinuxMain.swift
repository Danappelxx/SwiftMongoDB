import XCTest

@testable import MongoDBTestSuite

XCTMain([
    testCase(ClientTests.allTests),
    testCase(CollectionTests.allTests),
    testCase(DatabaseTests.allTests),
])
