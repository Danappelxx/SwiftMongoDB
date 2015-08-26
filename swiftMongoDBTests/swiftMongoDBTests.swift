//
//  swiftMongoDBTests.swift
//  swiftMongoDBTests
//
//  Created by Dan Appel on 8/14/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

//import XCTest
//@testable import swiftMongoDB
//
//class swiftMongoDBTests: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//
//    func testeExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock {
//            // Put the code you want to measure the time of here.
//        }
//    }
//
//}

import Quick
import Nimble
@testable import swiftMongoDB

class SwiftMongoDBSpec: QuickSpec {
    
    override func spec() {
        
        describe("Basic MongoDB operators") { () -> Void in
            
            // This suite assumes that the mongodb process is running
            
            let testDatabase = MongoDB(database: "database")
            let testCollection = MongoCollection(name: "collection")
            let testDocument = MongoDocument(data:
                [
                    "string" : "string",
                    "bool" : true,
                    "numbers" : [1,2,3],
                    "dictionary" : [
                        "key" : "value"
                    ]
                ]
            )
            let blankDocumentData = Dictionary<String, AnyObject>()

            afterEach {
                testCollection.remove(blankDocumentData)
            }


            it("connects successfully") {

                expect(testDatabase.connectionWasSuccessful).to(beTrue())
            }

            it("registers a collection successfully") {

                testDatabase.registerCollection(testCollection)

                expect(testCollection.isRegistered).to(beTrue())
            }


            it("inserts a document successfully") {

                // queries, then inserts, then queries again. succeeds if the second query is larger than the first query by 1
                
                let resultCount1 = testCollection.find().successValue?.count
                
                if resultCount1 == nil {
                    fail()
                    return
                }
                
                
                testCollection.insert(testDocument)

                let resultCount2 = testCollection.find().successValue?.count
                
                if resultCount2 == nil {
                    fail()
                    return
                }

                expect( (resultCount2! - resultCount1!) == 1).to(beTrue())
            }

            // needs to query for specific id, then insert document with said id, then query again
            it("queries for documents successfully") {

                let resultCount1 = testCollection.find(["_id" : testDocument.id]).successValue?.count

                if resultCount1 == nil {
                    fail()
                    return
                }

                testCollection.insert(testDocument)

                let resultCount2 = testCollection.find(["_id" : testDocument.id]).successValue?.count

                if resultCount2 == nil {
                    fail()
                    return
                }
                
                expect( (resultCount2! - resultCount1!) == 1).to(beTrue())
            }

            it("updates documents successfully") {
                expect(testCollection.update(query: blankDocumentData, document: ["updated" : true], type: .Basic).isSuccessful).to(beTrue())
            }

            it("removes documents successfully") {

                testCollection.insert(testDocument)

                testCollection.remove(["_id" : testDocument.id])

                let documents = testCollection.find(["_id" : testDocument.id]).successValue
                
                if documents == nil {
                    fail()
                } else {
                    expect(documents!).to(beEmpty())
                }
            }
        }
    }
}