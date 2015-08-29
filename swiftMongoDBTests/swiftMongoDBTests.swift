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
import mongo_c_driver

class SwiftMongoDBSpec: QuickSpec {
    
    override func spec() {
        
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
        let blankDocumentData = DocumentData()

        
        describe("The MongoDB connection") {

            it("connects successfully") {

                expect(testDatabase.connectionWasSuccessful).to(beTrue())
            }

            it("registers a collection successfully") {

                testDatabase.registerCollection(testCollection)

                expect(testCollection.isRegistered).to(beTrue())
            }
            
        }
        
        describe("The MongoDB collection") {

            afterEach {
                testCollection.remove(blankDocumentData)
            }

            it("inserts a document successfully") {

                // queries, then inserts, then queries again. succeeds if the second query is larger than the first query by 1
                
                let resultCount1 = testCollection.find().successValue?.count
                
                if resultCount1 == nil {
                    fail()
                    return
                }
                
                
                testCollection.insert(testDocument)

                // this line is really really strange - I'm not sure whats going on
                let resultCount2 = testCollection.find().successValue?.count
                
                if resultCount2 == nil {
                    fail()
                    return
                }
                
                if resultCount2 == 1000 {
                    fail()
                }

                expect( (resultCount2! - resultCount1!) == 1).to(beTrue())
            }

            // needs to query for specific id, then insert document with said id, then query again
            it("queries for documents successfully") {

                let resultCount1 = testCollection.find(["_id" : testDocument.id!]).successValue?.count

                if resultCount1 == nil {
                    fail()
                    return
                }

                testCollection.insert(testDocument)

                let resultCount2 = testCollection.find(["_id" : testDocument.id!]).successValue?.count

                if resultCount2 == nil {
                    fail()
                    return
                }

                if resultCount2 == 1000 {
                    fail()
                }
                
                // this could fail if the database wasn't cleaned before running this test
                expect( (resultCount2! - resultCount1!) == 1).to(beTrue())
            }

            it("updates documents successfully") {

                testCollection.insert(testDocument)

                let result1 = testCollection.first(id: testDocument.id!).successValue

                if result1 == nil {
                    fail()
                    return
                }

                testCollection.update(id: testDocument.id!, document: ["blank" : "document"], type: MongoCollection.UpdateType.Basic)

                let result2 = testCollection.first(["blank" : "document"]).successValue

                if result2 == nil {
                    fail()
                    return
                }

                result1?.printSelf()
                result2?.printSelf()

                expect(result1! == result2!).toNot(beTrue())
            }

            it("removes documents successfully") {

                testCollection.insert(testDocument)

                testCollection.remove(["_id" : testDocument.id!])

                let documents = testCollection.find(["_id" : testDocument.id!]).successValue
                
                if documents == nil {
                    fail()
                } else {
                    expect(documents!).to(beEmpty())
                }
            }
        }
        
        describe("The BSON processor") {
            
            // assumes that decoding works
            it("encodes BSON correctly") {

                let encodedData = MongoBSON(data: testDocument.data)

                let encodedDataRAW = bson_alloc()

                encodedData.copyTo(encodedDataRAW)

                let decodedData = MongoBSON.getDataFromBSON(encodedDataRAW)

                expect(decodedData == testDocument.data).to(beTrue())

            }

            it("decodes BSON correctly") {

                let decodedData = MongoBSON.getDataFromBSON(testDocument.BSONValue, ignoreObjectId: true)

                expect(decodedData == testDocument.data).to(beTrue())
            }
        }

        describe("The MongoDB commands") {

            it("create users successfully") {

                let createUserResult = testDatabase.createUser(user: "Test", password: "12345")

                expect(createUserResult).to(beTrue())
            }
        }

        describe("The Mongo objects") {

            struct TestObject: MongoObject {
                var prop1: String = "Str"
                var prop2: Int = 10
                var prop3: Bool = true
                var prop4: [String] = ["One", "Two", "Three", "Four"]
                var prop5: [String : AnyObject] = ["Hello" : "World", "Foo" : "Bar"]
            }

            it("properly converts into a document") {

                let testObject = TestObject()

                let documentFromObject = testObject.Document()

                expect(testObject.properties() == documentFromObject.data).to(beTrue())
            }
        }
    }
}