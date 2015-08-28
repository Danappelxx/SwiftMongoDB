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
            self.processPair(key: key, value: value, BSON: self.BSONValue)
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

    func processPair(key key: String, value: AnyObject, BSON: UnsafeMutablePointer<bson>) {

        if key == "_id" {
            
            let oidPtr = UnsafeMutablePointer<bson_oid_t>.alloc(1)
            bson_oid_from_string(oidPtr, (value as! String))
            
            bson_append_oid(BSON, key, oidPtr)
            
            return
        }
        
        switch value {

        case let value as String:
            
            bson_append_string(BSON, key, value)
//            print("appended string")
            break
            
        // covers both booleans and integers
        case let value as NSNumber:
            
            if value.isBool {
                bson_append_bool(BSON, key, value.intValue)
            } else {
                bson_append_int(BSON, key, value.intValue)
            }
            break
            
        case let value as Array<AnyObject>:
//            print("started appending array")
            bson_append_start_array(BSON, key)
            
            // recursively creates array by calling processPair on each element in the array
            for (index, val) in value.enumerate() {
                self.processPair(key: index.description, value: val, BSON: BSON)
            }
            
            bson_append_finish_array(BSON)
//            print("finished appending array")
            break
            
        case let value as [String:AnyObject]:
//            print("started appending object")
            bson_append_start_object(BSON, key)
            
            for (key, val) in value {
                self.processPair(key: key, value: val, BSON: BSON)
            }
            
            bson_append_finish_object(BSON)
//            print("finished appending object")
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
    
    static func getObjectIdFromBSON(BSON: UnsafeMutablePointer<bson>) -> String? {

        let iterator = bson_iterator_alloc()

        bson_iterator_init(iterator, BSON)

        let type = bson_find(iterator, BSON, "_id")

        if type != BSON_OID {
            return nil
        }


        let oidRAW = bson_iterator_oid(iterator)

        return self.getStringFromOid(oidRAW)
    }

    static func getDataFromBSON(BSON: UnsafeMutablePointer<bson>, ignoreObjectId: Bool = false) -> DocumentData {

        let iterator = bson_iterator_alloc()

        bson_iterator_init(iterator, BSON)


        var parsedData = DocumentData()

        while bson_iterator_next(iterator) != BSON_EOO {

            self.bsonIntoDictWithIterator(iterator: iterator, dict: &parsedData, ignoreObjectId: ignoreObjectId)
        }

        bson_iterator_dealloc(iterator)

        return parsedData
    }

    static func bsonIntoDictWithIterator(iterator iterator: UnsafeMutablePointer<bson_iterator>, inout dict: DocumentData, ignoreObjectId: Bool = false) {

        let type = bson_iterator_type(iterator)
        let key = String(NSString(UTF8String: bson_iterator_key(iterator))!)

        switch type.rawValue {

        case BSON_STRING.rawValue:

            let val = bson_iterator_string(iterator)

            let strVal = String ( NSString(UTF8String: val)! )
            dict[key] = strVal
            print("found string: \(strVal) with key: \(key)")

            return

        case BSON_DOUBLE.rawValue:

            let val = bson_iterator_double(iterator)


            dict[key] = val
            print("found double: \(val)")
            
            return

        case BSON_OID.rawValue:

            let val = bson_iterator_oid(iterator)

            let oid = self.getStringFromOid(val)
            
            
            if !ignoreObjectId {
                dict[key] = oid
            }

            print("found oid: \(oid)")
            
            return

        case BSON_BOOL.rawValue:
            
            let val = bson_iterator_bool(iterator)

            let boolVal = val == 1
            
            print("found bool: \(boolVal)")
            
            dict[key] = boolVal

            return

//        case BSON_DATE.rawValue:
//            
//            return
        case BSON_INT.rawValue:
            
            let val = bson_iterator_int(iterator)
            
            let intVal = Int(val)
            
            dict[key] = intVal

            print("found int: \(intVal)")

            return

        case BSON_LONG.rawValue:

            let val = bson_iterator_long(iterator)
            
            // this might not be smart
            let intVal = Int(val)
            
            dict[key] = intVal
            
            print("found long: \(intVal)")
            
            return

//        case BSON_TIMESTAMP.rawValue:
//            
//            return
        case BSON_ARRAY.rawValue:
            let subIterator = bson_iterator_alloc()

            bson_iterator_subiterator(iterator, subIterator)
            
            
            var arrDict = DocumentData()
            while bson_iterator_next(subIterator) != BSON_EOO {
                self.bsonIntoDictWithIterator(iterator: subIterator, dict: &arrDict)
            }
            
            let arr = arrDict.map { return $1 }
            
            dict[key] = arr
            
            print(arr)
            
            bson_iterator_dealloc(subIterator)
            
            return

        case BSON_OBJECT.rawValue:
//            let subIterator = bson_iterator_alloc()
            
            
            let subobject = bson_alloc()
            
            bson_iterator_subobject_init(iterator, subobject, 1)

            dict[key] = self.getDataFromBSON(subobject)
            
            bson_destroy(subobject)

            return

        case BSON_UNDEFINED.rawValue:

            dict[key] = nil

            print("found undefined")

            return
        case BSON_NULL.rawValue:
            dict[key] = nil
            
            print("found null")
            return

        case BSON_EOO.rawValue:
            print("shouldn't be here.")
            return

//        case BSON_MAXKEY.rawValue:
//        case BSON_MINKEY.rawValue:
//        case BSON_BINDATA.rawValue:

        default:
            print("invalid type")
        }

        // for reference:
        //        public var BSON_EOO: bson_type { get }
        //        public var BSON_DOUBLE: bson_type { get }
        //        public var BSON_STRING: bson_type { get }
        //        public var BSON_OBJECT: bson_type { get }
        //        public var BSON_ARRAY: bson_type { get }
        //        public var BSON_BINDATA: bson_type { get }
        //        public var BSON_UNDEFINED: bson_type { get }
        //        public var BSON_OID: bson_type { get }
        //        public var BSON_BOOL: bson_type { get }
        //        public var BSON_DATE: bson_type { get }
        //        public var BSON_NULL: bson_type { get }
        //        public var BSON_REGEX: bson_type { get }
        //        /**< Deprecated. */
        //        public var BSON_DBREF: bson_type { get }
        //        public var BSON_CODE: bson_type { get }
        //        public var BSON_SYMBOL: bson_type { get }
        //        public var BSON_CODEWSCOPE: bson_type { get }
        //        public var BSON_INT: bson_type { get }
        //        public var BSON_TIMESTAMP: bson_type { get }
        //        public var BSON_LONG: bson_type { get }
        //        public var BSON_MAXKEY: bson_type { get }
        //        public var BSON_MINKEY: bson_type { get }

    }
}



// Stolen from SwiftyJSON
// https://github.com/SwiftyJSON/SwiftyJSON/blob/master/Source/SwiftyJSON.swift#L1118

private let trueNumber = NSNumber(bool: true)
private let falseNumber = NSNumber(bool: false)
private let trueObjCType = String.fromCString(trueNumber.objCType)
private let falseObjCType = String.fromCString(falseNumber.objCType)

// MARK: - NSNumber: Comparable

extension NSNumber: Swift.Comparable {

    /// Returns whether the number is of boolean type
    var isBool:Bool {
        get {
            let objCType = String.fromCString(self.objCType)
            if (self.compare(trueNumber) == NSComparisonResult.OrderedSame &&  objCType == trueObjCType) ||  (self.compare(falseNumber) == NSComparisonResult.OrderedSame && objCType == falseObjCType){
                return true
            } else {
                return false
            }
        }
    }
}

public func ==(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == NSComparisonResult.OrderedSame
    }
}

public func !=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return !(lhs == rhs)
}

public func <(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
    }
}

public func >(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == NSComparisonResult.OrderedDescending
    }
}

public func <=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != NSComparisonResult.OrderedDescending
    }
}

public func >=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != NSComparisonResult.OrderedAscending
    }
}
