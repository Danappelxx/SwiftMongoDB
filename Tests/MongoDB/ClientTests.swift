//
//  ClientTests.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 3/7/16.
//  Copyright © 2016 dvappel. All rights reserved.
//

import XCTest
import MongoDB

/// This variable is used in other test cases so it needs to be declared here
let client = try! Client(host: "localhost", port: 27017)

// Doesn't seem like there's a lot to test...
class ClientTests: XCTestCase {
    func testClientGetsDatabaseNames() throws {
        XCTAssertNotNil(client.databaseNames)
    }

    func testClientPerformsBasicCommands() throws {
        let response = try client.basicCommand(["ping": 1], databaseName: "local")

        XCTAssertNotNil(response["ok"])
    }

    func testClientGetsDatabaseCursor() throws {
        let cursor = try client.getDatabasesCursor()

        let database = cursor.next()

        XCTAssertNotNil(database?["name"])
    }

    func testClientGetsServerStatus() throws {
        let status = try client.getServerStatus()

        XCTAssertNotNil(status["ok"])
    }
}

extension ClientTests {
    static var allTests: [(String, ClientTests -> () throws -> Void)] {
        return [
            ("testClientGetsDatabaseNames", testClientGetsDatabaseNames),
            ("testClientPerformsBasicCommands", testClientPerformsBasicCommands),
            ("testClientGetsDatabaseCursor", testClientGetsDatabaseCursor),
            ("testClientGetsServerStatus", testClientGetsServerStatus)
        ]
    }
}
