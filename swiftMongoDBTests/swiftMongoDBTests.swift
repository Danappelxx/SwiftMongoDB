//
//  swiftMongoDBTests.swift
//  swiftMongoDBTests
//
//  Created by Dan Appel on 8/14/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//


import Quick
import Nimble
@testable import swiftMongoDB

class SwiftMongoDBSpec: QuickSpec {
    
    override func spec() {
        
        // This suite assumes that the mongodb process is running

        let client = try! MongoClient(host: "localhost", port: 27017, database: "test")

        let collection = MongoCollection(collectionName: "subjects", client: client)
        
        let document = MongoDocument(data: [
            "string" : "string",
//            "bool" : true,
            "number" : 123,
            "numbers" : [1,2,3],
            "dictionary" : [
                "key" : "value"
            ],
            // this is cheating but whatevs
            "_id" : [
                "$oid" : "55ea18cb1baf6a0fdb2191c2"
            ],
        ])
        
        describe("The MongoDB collection") {

            afterEach {
                try! collection.remove(DocumentData())
            }

            it("inserts a document successfully") {
                
                let resultBefore = try! collection.find().count
                
                try! collection.insert(document)
                
                let resultAfter = try! collection.find().count
                
                expect(resultAfter - resultBefore == 1).to(beTrue())

            }

            // needs to query for specific id, then insert document with said id, then query again
            it("queries for documents successfully") {

                let results = try! collection.find()
                
                print(results)

//                let resultCount1 = try! testCollection.find(["_id" : testDocument.id!]).count
//
//                try! testCollection.insert(testDocument)
//
//                let resultCount2 = try! testCollection.find(["_id" : testDocument.id!]).count
//
//                if resultCount2 == 1000 {
//                    fail()
//                }
//                
//                // this could fail if the database wasn't cleaned before running this test
//                expect( (resultCount2 - resultCount1) == 1).to(beTrue())
            }

            it("updates documents successfully") {

                try! collection.insert(document)

                let resultBefore = try! collection.findOne(document.data)
                
                // run it through the encoder & decoder process to give it fair grounds
                let resultBeforeData = try! MongoBSONDecoder(BSON: MongoBSONEncoder(data: resultBefore.data).BSONRAW).result

                let newData = [
                    "_id" : [
                        "$oid" : "55ea18cb1baf6a0fdb2191c2"
                    ],
                    "hey" : "there"
                ]

                try! collection.update(document.data, newValue: newData)

                let resultAfter = try! collection.findOne(newData)

                expect(resultBeforeData != resultAfter.data && resultAfter.data == newData).to(beTrue())

//                try! testCollection.insert(testDocument)
//
//                let result1 = try! testCollection.findOne(id: testDocument.id!)
//
//
//                try! testCollection.update(id: testDocument.id!, document: ["blank" : "document"], type: MongoCollection.UpdateType.Basic)
//
//                let result2 = try! testCollection.findOne(["blank" : "document"])
//
//
//                result1.printSelf()
//                result2.printSelf()
//
//                expect(result1 == result2).toNot(beTrue())
            }

            it("removes documents successfully") {

                try! collection.insert(document)

                let countBefore = try! collection.find().count

                try! collection.remove(document.data)

                let countAfter = try! collection.find().count

                expect(countBefore - countAfter == 1).to(beTrue())
            }
        }

        describe("The BSON processor") {

            // assumes that decoding works
            it("encodes BSON correctly") {

                let encodedDataRAW = try! MongoBSONEncoder(data: document.data).BSONRAW

                let decodedData = try! MongoBSONDecoder(BSON: encodedDataRAW).result

                expect(decodedData == document.data).to(beTrue())
            }

            it("decodes BSON correctly") {

                let decodedData = try! MongoBSONDecoder(BSON: document.BSONRAW).result
                
                expect(decodedData == document.data).to(beTrue())
            }
        }

//        describe("The MongoDB commands") {
//
//            it("create users successfully") {
//
//                let createUserResult = testDatabase.createUser(username: "Test", password: "12345")
//
//                expect(createUserResult).to(beTrue())
//            }
//        }
//
//        describe("The Mongo objects") {
//
//            struct TestObject: MongoObject {
//                var prop1: String = "Str"
//                var prop2: Int = 10
//                var prop3: Bool = true
//                var prop4: [String] = ["One", "Two", "Three", "Four"]
//                var prop5: [String : AnyObject] = ["Hello" : "World", "Foo" : "Bar"]
//            }
//
//            it("properly converts into a document") {
//
//                let testObject = TestObject()
//
//                let documentFromObject = testObject.Document()
//
//                expect(testObject.properties() == documentFromObject.data).to(beTrue())
//            }
//        }
    }
}