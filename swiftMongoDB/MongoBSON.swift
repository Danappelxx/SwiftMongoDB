////
////  MongoBSON.swift
////  swiftMongoDB
////
////  Created by Dan Appel on 8/20/15.
////  Copyright © 2015 Dan Appel. All rights reserved.
////

import Foundation
import SwiftyJSON

class MongoBSONEncoder {

    let BSONRAW: _bson_ptr_mutable

    let data: DocumentData

    init(data: DocumentData) throws {

        self.BSONRAW = bson_new()
        self.data = data

        guard let JSONData = JSON(self.data).rawString() else {
            throw MongoError.CorruptDocument
        }

        let JSONDataRAW = NSString(string: JSONData).UTF8String

        var error = bson_error_t()
        bson_init_from_json(self.BSONRAW, JSONDataRAW, JSONData.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), &error)
        
        if error.code.mongoError != MongoError.NoError {
            print( errorMessageToString(&error.message) )
            throw error.code.mongoError
        }
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
    var result: DocumentData {
        return self.resultData
    }

    private var resultData: DocumentData
    var resultJSON: String? {
        return MongoBSONDecoder.BSONToJSON(self.BSONRAW)
    }

    static func BSONToJSON(BSON: _bson_ptr_immutable) -> String? {
        let rawJSON = NSString(UTF8String: bson_as_json(BSON, nil))
        
        guard let json = rawJSON else {
            return nil
        }

        return String(json)
    }

    init(BSON: _bson_ptr_immutable) throws {
        self.BSONRAW = BSON

        self.resultData = DocumentData()

        do {
            self.resultData = try MongoBSONDecoder.decode(BSON)
        } catch {
            throw error
        }
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