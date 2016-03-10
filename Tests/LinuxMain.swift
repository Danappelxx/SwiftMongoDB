import XCTest

@testable import MongoDBtest

XCTMain([
   ClientTests(),
   CollectionTests(),
   DatabaseTests()
])
