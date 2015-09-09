//
//  swiftMongoDBTests.swift
//  swiftMongoDBTests
//
//  Created by Dan Appel on 8/14/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//


import Quick
import Nimble
import SwiftyJSON
@testable import swiftMongoDB

class SwiftMongoDBSpec: QuickSpec {
    
    override func spec() {
        
        // This suite assumes that the mongodb process is running

        let client = try! MongoClient(host: "localhost", port: 27017, database: "test")

        let collection = MongoCollection(collectionName: "subjects", client: client)

        let document = MongoDocument(data: [
            "string" : "string",
            "bool" : true,
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
        
        try! collection.remove()
        
        describe("The MongoDB collection") {

            beforeEach {
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

                let objId = ["$oid":"55ef8ab5bb6a9b5717de15e9"]
                
                let resultBefore = try! collection.find(["_id":objId]).count
                
                var doc2 = document.data
                doc2["_id"] = objId
                
                try! collection.insert(doc2)
                
                let resultAfter = try! collection.find(["_id":objId]).count

                expect(resultAfter - resultBefore == 1).to(beTrue())
            }

            it("updates documents successfully") {

                try! collection.insert(document)

                let resultBefore = try! collection.find(document.data)[0]

                // run it through the encoder & decoder process to give it fair grounds
                var resultBeforeDataRAW = bson_t()
                try! MongoBSONEncoder(data: resultBefore.data).copyTo(&resultBeforeDataRAW)
                let resultBeforeData = try! MongoBSONDecoder(BSON: &resultBeforeDataRAW).result

                let newData = [
                    "_id" : document.data["_id"]!,
                    "hey" : "there"
                ]

                try! collection.update(document.data, newValue: newData)

                let resultAfter = try! collection.find(newData)[0]

                let newMatchesOld = resultBeforeData == resultAfter.data
                let newMatchesNew = resultAfter.data == newData
                expect(!newMatchesOld && newMatchesNew).to(beTrue())
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

                var encodedDataRAW = bson_t()
                try! MongoBSONEncoder(data: document.data).copyTo(&encodedDataRAW)
                
                let encodedData = MongoBSONDecoder.BSONToJSON(&encodedDataRAW)!.parseJSON!
                let encodedDataJSON = JSON(encodedData).rawString()!
                
                let decodedData = JSON(document.data).rawString()!.parseJSON!
                let decodedDataJSON = JSON(decodedData).rawString()!

                expect(encodedDataJSON == decodedDataJSON).to(beTrue())
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