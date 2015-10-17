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
        
        let document = try! MongoDocument(data: [
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
        
        describe("The MongoDB client") {
            
            it("can list the databases") {
                let databases = client.getDatabaseNames()
                
                expect(databases.contains("test")).to(beTrue())
            }
            
            it("can list the collections") {
                
                let collections = client.getCollectionNamesInDatabase("test")
                
                expect(collections.contains("subjects")).to(beTrue())
            }
            
        }
        
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
                
                try! collection.insert(doc2, containsObjectId: true)
                
                let resultAfter = try! collection.find(["_id":objId]).count
                
                expect(resultAfter - resultBefore == 1).to(beTrue())
            }
            
            it("updates documents successfully") {
                
                try! collection.insert(document)
                
                let resultBefore = try! collection.find(document.data)[0]
                
                // run it through the encoder & decoder process to give it fair grounds
                var resultBeforeDataRAW = bson_t()
                try! MongoBSONEncoder(data: resultBefore.data).copyTo(&resultBeforeDataRAW)
                let resultBeforeData = try! MongoBSONDecoder(BSON: &resultBeforeDataRAW).result.data
                
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
                
                let decodedData = try! MongoBSONDecoder(BSON: document.BSONRAW).result.data
                
                expect(decodedData == document.data).to(beTrue())
            }
        }
        
        describe("The MongoDB commands") {
            
            it("performs collection commands correctly") {
                //                { collStats: "collection" , scale : 1024, verbose: true }
                
                let command: DocumentData = [
                    "collStats" : collection.collectionName,
                ]
                
                try! collection.performBasicCollectionCommand(command)
            }
        }
        
        describe("The MongoDocument") {
            
            context("initialization process") {
                
                it("works with raw DocumentData") {
                    let docBefore = try! MongoDocument(data: document.data)
                    
                    var docRAW = bson_t()
                    try! MongoBSONEncoder(data: docBefore.data).copyTo(&docRAW)
                    let docAfter = try! MongoBSONDecoder(BSON: &docRAW).result
                    
                    expect(docBefore == docAfter).to(beTrue())
                }
                
                it("works with JSON") {
                    
                    let docBefore = try! MongoDocument(JSON: JSON(document.data).rawString()!).JSONString!
                    
                    var docRAW = bson_t()
                    try! MongoBSONEncoder(JSON: docBefore).copyTo(&docRAW)
                    let docAfter = try! MongoBSONDecoder(BSON: &docRAW).resultJSON!
                    
                    expect(docBefore.parseJSONDocumentData! == docAfter.parseJSONDocumentData!).to(beTrue())
                }
                
                it("works with MongoObject schemas") {
                    
                    struct TestObject: MongoObject {
                        var prop1: String = "Str"
                        var prop2: Int = 10
                        var prop3: Bool = true
                        var prop4: [String] = ["One", "Two", "Three", "Four"]
                        var prop5: [String : AnyObject] = ["Hello" : "World", "Foo" : "Bar"]
                    }
                    
                    let testObject = TestObject()
                    
                    let documentFromObject = try! testObject.Document()
                    
                    expect(testObject.properties() == documentFromObject.dataWithoutObjectId).to(beTrue())
                }
            }
            
            
        }
        
        describe("The Mongo objects") {
            
            
        }
    }
}