//
//  swiftMongoDBTests.swift
//  swiftMongoDBTests
//
//  Created by Dan Appel on 8/14/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//


import Quick
import Nimble
import bson
import mongoc
@testable import SwiftMongoDB

class SwiftMongoDBSpec: QuickSpec {
    
    override func spec() {
        
        // This suite assumes that the mongodb process is running
        let client = try! MongoClient(host: "localhost", port: 27017)
        let database = MongoDatabase(client: client, name: "test")
        let collection = MongoCollection(name: "test", database: database)
        
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
        
        try! collection.insert([:])
        try! collection.remove()
        
        describe("The MongoDB client") {
            
            it("can list the databases") {
                let databases = try! client.getDatabaseNames()
                
                expect(databases.count).to(beGreaterThan(0))
            }
        }
        
        describe("The MongoDB database") {
            
            it("can list the collections") {
                
                let collections = try! database.getCollectionNames()
                
                expect(collections.contains("test")).to(beTrue())
            }
        }
        
        describe("The MongoDB collection") {
            
            beforeEach {
                try! collection.remove([:])
            }
            
            describe("insert method") {

                it("inserts a document successfully") {

                    let resultBefore = try! collection.find().count

                    try! collection.insert(document)

                    let resultAfter = try! collection.find().count

                    expect(resultAfter - resultBefore).to(equal(1))

                }
            }
            
            describe("find method") {
                // needs to query for specific id, then insert document with said id, then query again
                it("queries for documents successfully") {
                    
                    let objId = ["$oid":"55ef8ab5bb6a9b5717de15e9"]
                    
                    let resultBefore = try! collection.find(["_id":objId]).count
                    
                    var doc2 = document.data
                    doc2["_id"] = objId
                    
                    try! collection.insert(doc2)
                    
                    let resultAfter = try! collection.find(["_id":objId]).count
                    
                    expect(resultAfter - resultBefore).to(equal(1))
                }
                
                it("limits fields of documents successfully") {
                    
                    let objId = ["$oid":"55ef8ab5bb6a9b5717de15e9"]
                    
                    let resultAllFields = try! collection.findOne(["_id":objId])
                    
                    expect(resultAllFields?.data.count == document.data.count)
                    
                    let resultOneField = try! collection.findOne(["_id":objId], fields: ["string": true, "_id": false])
                    
                    expect(resultOneField?.data.count == 1)
                }
                
                it("properly applies the limit flag") {

                    var data = document.data
                    data["_id"] = nil // to not have duplicate keys

                    // insert 10 times
                    for _ in 0..<10 {
                        try! collection.insert(data)
                    }
                    let count = try! collection.find(limit: 3).count

                    expect(count).to(equal(3))
                }
            }
            
            describe("update method") {

                it("updates documents successfully") {

                    try! collection.insert(document)

                    let resultBefore = try! collection.find(document.data)[0]

                    // run it through the encoder & decoder process to give it fair grounds
                    let resultBeforeDataRaw = try! MongoBSON(data: resultBefore.data).bson
                    let resultBeforeData = try! MongoBSON(bson: resultBeforeDataRaw).data

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
            }
            
            describe("remove method") {

                it("removes documents successfully") {

                    try! collection.insert(document)

                    let countBefore = try! collection.find().count

                    try! collection.remove(document.data)

                    let countAfter = try! collection.find().count

                    expect(countBefore - countAfter).to(equal(1))
                }
            }
        }
        
        describe("The BSON processor") {
            
            // assumes that decoding works
            it("encodes BSON correctly") {

                let encodedDataRaw = try! MongoBSON(data: document.data).bson
                
                do {
                    let encodedData = try MongoBSON(bson: encodedDataRaw).data
                    let encodedDataJSON = try encodedData.toJSON()

                    let decodedData = try document.data.toJSON().parseJSONDocumentData()!
                    let decodedDataJSON = try decodedData.toJSON()

                    expect(encodedDataJSON).to(equal(decodedDataJSON))
                } catch {
                    print(error)
                    fail()
                }
            }
            
            it("decodes BSON correctly") {

                let decodedData = try! MongoBSON(bson: document.bson).data

                expect(decodedData == document.data).to(beTrue())
            }
        }
        
        describe("The MongoDB commands") {
            
            it("performs collection commands correctly") {
                
                let command: DocumentData = [
                    "ping" : 1,
                ]
                
                let data = try? collection.performBasicCollectionCommand(command)
                
                expect(data).toNot(beNil())
            }
        }
        
        describe("The MongoDocument") {
            
            context("initialization process") {
                
                it("works with raw DocumentData") {
                    let docBefore = try! MongoDocument(data: document.data)
                    
                    let docRaw = try! MongoBSON(data: docBefore.data).bson
                    let docAfterData = try! MongoBSON(bson: docRaw).data
                    let docAfter = try! MongoDocument(data: docAfterData)
                    
                    expect(docBefore == docAfter).to(beTrue())
                }
                
                it("works with JSON") {

                    let docBefore = try! MongoDocument(JSON: try! document.data.toJSON())
                    let docBeforeJson = docBefore.JSON!

                    let docRaw = try! MongoBSON(json: docBeforeJson).bson
                    
                    let docAfterJson = try! MongoBSON(bson: docRaw).json
                    
                    let docBeforeParsed = try! docBeforeJson.parseJSONDocumentData()!
                    let docAfterParsed = try! docAfterJson.parseJSONDocumentData()!
                    
                    expect(docBeforeParsed == docAfterParsed).to(beTrue())
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
        
        describe("Sequence extension for pointers") {
            
            it("works with numbers") {
                
                var a: Int8 = 1
                var b: Int8 = 2
                
                withUnsafeMutablePointers(&a, &b) { f, s in
                    
                    let ptr = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(3)
                    
                    ptr.advancedBy(0).memory = f
                    ptr.advancedBy(1).memory = s
                    ptr.advancedBy(2).memory = nil // null-terminated
                    
                    let ints = ptr.sequence()!
                        .map {
                            Int($0.memory)
                        }
                    
                    expect(ints).to(equal([1, 2]))
                }
            }
            
            it("works with mongoc strings") {
                
                let namesRaw = mongoc_client_get_database_names(client.clientRaw, nil)
                
                let names = namesRaw.sequence()!
                    .map { (cStr: UnsafeMutablePointer<Int8>) -> String? in
                        return String(UTF8String: cStr)
                    }
                    .flatMap { $0 }
                
                expect(names.contains("test")).to(beTrue())
            }
            
            it("does not work with non-integer types") {
                var dict = ["hello":"world"]

                withUnsafeMutablePointer(&dict) { dictPtr in
                    let ptr = UnsafeMutablePointer<UnsafeMutablePointer<[String:String]>>.alloc(1)
                    ptr.memory = dictPtr

                    expect(ptr.sequence()).to(beNil())
                }
            }
        }
    }
}
