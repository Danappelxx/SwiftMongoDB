//
//  MongoBSON.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation
import SwiftyJSON

class MongoBSONEncoder {

    let BSONRAW: _bson_ptr_mutable

    let data: DocumentData

    init(JSON: String) throws {
        
        self.BSONRAW = bson_new()
        self.data = JSON.parseJSONDocumentData!

        let JSONDataRAW = NSString(string: JSON).UTF8String
        
        var error = bson_error_t()
        bson_init_from_json(self.BSONRAW, JSONDataRAW, JSON.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), &error)
        
        if error.code.mongoError != MongoError.NoError {
            print( errorMessageToString(&error.message) )
            throw error.code.mongoError
        }
    }
    
    convenience init(data: DocumentData) throws {

        guard let JSONData = JSON(data).rawString() else {
            throw MongoError.CorruptDocument
        }

        try self.init(JSON: JSONData)
    }

    deinit {
        bson_destroy(self.BSONRAW)
    }
    
    func copyTo(destination: _bson_ptr_mutable) {
        bson_copy_to(self.BSONRAW, destination)
    }

    static func generateObjectId() -> String {
        
        let oid = UnsafeMutablePointer<bson_oid_t>.alloc(1)
        
        bson_oid_init(oid, bson_context_get_default())

        let oidStr = self.getStringFromOid(oid)

        oid.dealloc(1)

        return oidStr
    }
    
    private static func getStringFromOid(oid: UnsafeMutablePointer<bson_oid_t>) -> String {

        let oidStrRAW = UnsafeMutablePointer<Int8>.alloc(100)

        bson_oid_to_string(oid, oidStrRAW)

        let oidStr = NSString(UTF8String: oidStrRAW)

        oidStrRAW.dealloc(100)

        return String(oidStr!)
    }
}

class MongoBSONDecoder {

    let BSONRAW: _bson_ptr_immutable

    // result should be read only
    var result: MongoDocument {
        return try! MongoDocument(data: self.resultData)
    }

    private var resultData: DocumentData
    var resultJSON: String? {
        return MongoBSONDecoder.BSONToJSON(self.BSONRAW)
    }

    static func BSONToJSON(BSON: _bson_ptr_immutable) -> String? {
        let json = String(UTF8String: bson_as_json(BSON, nil))

        return json
    }

    init(BSON: _bson_ptr_immutable) throws {
        self.BSONRAW = BSON

        self.resultData = DocumentData()

        self.resultData = try MongoBSONDecoder.decode(BSON)
    }

    static private func decode(BSON: _bson_ptr_immutable) throws -> DocumentData {

        let JSONString = String(self.BSONToJSON(BSON)!)

        // this is broken up into pieces for readability
        // turn string into NSData
        guard let JSONDataRAW = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else {

            throw MongoError.CorruptDocument

        }

        // init JSON from NSData, get dictionary object from it
        guard let JSONData = JSON(data: JSONDataRAW).dictionaryObject else {
            throw MongoError.CorruptDocument
        }

        return JSONData
    }
}
