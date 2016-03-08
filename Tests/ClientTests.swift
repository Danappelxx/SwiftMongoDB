//
//  ClientTests.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 3/7/16.
//  Copyright © 2016 dvappel. All rights reserved.
//

import XCTest
import MongoDB

class ClientTests: XCTestCase {

    let client: Client = try! Client.init(host: "localhost", port: 27017)

    func testExample() {
        XCTAssert(true)
    }

    func testClientGetsDatabaseNames() throws {
        // sanity check
        try! self.client.checkConnection()

        let names = try self.client.getDatabaseNames()

        XCTAssert(names.count > 0)
    }
}
