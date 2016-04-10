//
//  CollectionTests.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 3/7/16.
//  Copyright © 2016 dvappel. All rights reserved.
//

import XCTest
import MongoDB

/// This variable is used in other test cases so it needs to be declared here
let collection = Collection(database: database, name: "test")

class CollectionTests: XCTestCase {

    override func setUp() {
        try! collection.remove()
    }

    let testDocument: BSON.Document = [
        "_id": .ObjectID(BSON.ObjectID()), // random oid
        "string": "string"
    ]

    // same id, different value for key "string"
    var testDocument2: BSON.Document {
        var original = testDocument
        original["string"] = .String("different string")
        return original
    }

    func testCollectionFindsDocuments() throws {

        try collection.insert(testDocument)

        let found = try collection.find(query: testDocument).nextDocument()!

        XCTAssert(found == testDocument)
    }

    func testCollectionInsertsDocuments() throws {
        let initial = try collection.count()

        try collection.insert(testDocument)

        let after = try collection.count()

        XCTAssert(after - initial == 1)
    }

    func testCollectionUpdatesDocuments() throws {

        try collection.insert(testDocument)

        let query: BSON.Document = [
            "_id": .ObjectID(testDocument["_id"]!.objectIDValue!)
        ]

        let original = try collection.find(query: query).nextDocument()!

        try collection.update(query: testDocument, newValue: testDocument2)

        let updated = try collection.find(query: query).nextDocument()!

        XCTAssertNotEqual(original["string"], updated["string"])
    }

    func testCollectionRemovesDocuments() throws {

        try collection.insert(testDocument)

        let initial = try collection.count()

        try collection.remove()

        let after = try collection.count()

        XCTAssert(after == 0)
        XCTAssert(after < initial)
    }

    func testCollectionPerformsCommands() throws {
        let response = try collection.basicCommand(command: ["ping": 1])

        XCTAssertNotNil(response["ok"])
    }
}

extension CollectionTests {
    static var allTests: [(String, CollectionTests -> () throws -> Void)] {
        return [
            ("testCollectionFindsDocuments", testCollectionFindsDocuments),
            ("testCollectionInsertsDocuments", testCollectionInsertsDocuments),
            ("testCollectionUpdatesDocuments", testCollectionUpdatesDocuments),
            ("testCollectionRemovesDocuments", testCollectionRemovesDocuments),
            ("testCollectionPerformsCommands", testCollectionPerformsCommands)
        ]
    }
}
