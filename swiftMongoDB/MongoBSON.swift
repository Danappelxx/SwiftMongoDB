//
//  MongoBSON.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation
import mongo_c_driver

// MARK: - MongoBSON
internal class MongoBSON {
    
    let BSONValue = bson_alloc()
    var data: DocumentData
    
    init(data: DocumentData, withObjectId objectId: String? = nil) {

        self.data = data
        
        // init bson
        bson_init(self.BSONValue)
        
        // add object id if necessary
        if let objectId = objectId {
            let oid = UnsafeMutablePointer<bson_oid_t>.alloc(1)
            bson_oid_from_string(oid, objectId)
            
            bson_append_oid(self.BSONValue, "_id", oid)
            
//            bson_append_new_oid(self.BSONValue, "_id")
            print("appended object id")
        }
        
        
        // go through each key:value pair and append it to the bson object
        for (key, value) in data {
            self.processPair(key: key, value: value)
        }
        
        // error handling
        let bsonError = UInt32(self.BSONValue.memory.err)
        switch bsonError {
            
        case BSON_VALID.rawValue:
            print("bson is valid")
            break
        case BSON_NOT_UTF8.rawValue:
            print("not valid utf8 input")
            break
        case BSON_FIELD_HAS_DOT.rawValue:
            print("one of the fields has a dot")
            break
        case BSON_FIELD_INIT_DOLLAR.rawValue:
            print("one of the fields has a dollar sign")
            break
        case BSON_ALREADY_FINISHED.rawValue:
            print("bson processing is already finished")
            break
        default:
            print("unknown bson error with code: \(self.BSONValue.memory.err)")
        }
        
        // complete bson
        bson_finish(self.BSONValue)
        print("completed bson")
    }

    deinit {
        bson_destroy(self.BSONValue)
    }

    // need to implement proper error handling - for example
    // if you have a dict where you use integers as keys
    // bson processing will fail but it will not be reported

    func processPair(key key: String, value: AnyObject) {

        if key == "_id" {
            
            let oidPtr = UnsafeMutablePointer<bson_oid_t>.alloc(1)
            bson_oid_from_string(oidPtr, (value as! String))
            
            bson_append_oid(self.BSONValue, key, oidPtr)
            
            return
        }
        
        switch value {

        case let value as String:
            
            bson_append_string(self.BSONValue, key, value)
            print("appended string")
            break
            
        case let value as Int:
            bson_append_int(self.BSONValue, key, Int32(value))
            print("appended int")
            break
            
        case let value as Array<AnyObject>:
            print("started appending array")
            bson_append_start_array(self.BSONValue, key)
            
            // recursively creates array by calling processPair on each element in the array
            for (index, val) in value.enumerate() {
                self.processPair(key: index.description, value: val)
            }
            
            bson_append_finish_array(self.BSONValue)
            print("finished appending array")
            break
            
        case let value as [String:AnyObject]:
            print("started appending object")
            bson_append_start_object(self.BSONValue, key)
            
            for (key, val) in value {
                self.processPair(key: key, value: val)
            }
            
            bson_append_finish_object(self.BSONValue)
            print("finished appending object")
            break
            
        default:
            print("could not resolve type of value: \(value) with key: \(key)")
            break
        }
    }
    
    func copyTo(BSON: UnsafeMutablePointer<bson>) {
        bson_copy(BSON, self.BSONValue)
    }

    static func generateObjectId() -> String {
        
        let oid = UnsafeMutablePointer<bson_oid_t>.alloc(1)

        bson_oid_gen(oid)


        let oidStrRAW = UnsafeMutablePointer<Int8>.alloc(100)
        
//        return ""

        bson_oid_to_string(oid, oidStrRAW)

        let oidStr = NSString(UTF8String: oidStrRAW)

        oid.dealloc(1)
        oidStrRAW.dealloc(100)
        
        print(oidStr)

        return String(oidStr!)
    }
    
    static func getObjectIdFromBSON(BSON: UnsafeMutablePointer<bson>) -> String {
        
        return ""
    }
}