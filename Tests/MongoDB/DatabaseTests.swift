//
//  DatabaseTests.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 3/7/16.
//  Copyright © 2016 dvappel. All rights reserved.
//

import XCTest
import MongoDB

/// This variable is used in other test cases so it needs to be declared here
let database = Database(client: client, name: "local")

// Doesn't seem like there's a lot to test...
class DatabaseTests: XCTestCase {
    func testDatabaseGetsCollectionNames() throws {
        let names = database.collectionNames

        XCTAssertNotNil(names)
        XCTAssert(names!.count > 0)
    }

    func testDatabasePerformsCommands() throws {
        let response = try database.basicCommand(command: ["ping": 1])

        XCTAssertNotNil(response["ok"])
    }
}

extension DatabaseTests {
    static var allTests: [(String, DatabaseTests -> () throws -> Void)] {
        return [
            ("testDatabaseGetsCollectionNames", testDatabaseGetsCollectionNames),
            ("testDatabasePerformsCommands", testDatabasePerformsCommands)
        ]
    }
}
