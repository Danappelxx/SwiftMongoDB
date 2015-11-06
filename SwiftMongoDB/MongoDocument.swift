//
//  MongoDocument.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import bson

public class MongoDocument {

    let BSONRAW: _bson_ptr_mutable = bson_new()
    
    public var JSONString: String? {
        return JSON(self.data).rawString()
    }
    
    public var JSONValue: JSON {
        return JSON(self.data)
    }

    public var dataWithoutObjectId: DocumentData {
        var copy = self.data
        copy["_id"] = nil
        return copy
    }

    public var data: DocumentData {
        return self.documentData
    }
    
    public var id: String? {
        return self.data["_id"]?["$oid"] as? String
    }

    private var documentData = DocumentData()
    
    private func initBSON() {
        try! MongoBSONEncoder(data: self.data).copyTo(self.BSONRAW)
    }

    public init(let data: DocumentData) throws {
        self.documentData = data
        self.initBSON()
    }

    convenience public init(var data: DocumentData, withObjectId objectId: String) throws {

        data["_id"] = ["$oid" : objectId]
        
        try self.init(data: data)
    }

    convenience public init(JSON: String, withObjectId objectId: String) throws {

        guard let data = JSON.parseJSONDocumentData else {
            throw MongoError.CorruptDocument
        }

        try self.init(data: data, withObjectId: objectId)
    }
    
    convenience public init(JSON: String) throws {

        guard let data = JSON.parseJSONDocumentData else {
            throw MongoError.CorruptDocument
        }

        try self.init(data: data)
    }
    
    convenience public init(withSchemaObject object: MongoObject, withObjectID objectId: String) throws {

        let data = object.properties()
        
        try self.init(data: data, withObjectId: objectId)
    }
    
    convenience public init(withSchemaObject object: MongoObject) throws {
        
        let data = object.properties()
        
        try self.init(data: data)
    }
    
    private func generateObjectId() -> String {

        var oidRAW = bson_oid_t()

        bson_oid_init(&oidRAW, nil)


        let oidStrRAW = UnsafeMutablePointer<Int8>.alloc(100)
//        try to minimize this memory usage while retaining safety, reference:
//        4 bytes : The UNIX timestamp in big-endian format.
//        3 bytes : The first 3 bytes of MD5(hostname).
//        2 bytes : The pid_t of the current process. Alternatively the task-id if configured.
//        3 bytes : A 24-bit monotonic counter incrementing from rand() in big-endian.


        bson_oid_to_string(&oidRAW, oidStrRAW)
        
        let oidStr = NSString(UTF8String: oidStrRAW)
        
        oidStrRAW.destroy()

        return oidStr as! String
    }
    
    public func getObjectFromKey(key : String) -> AnyObject? {
        return self.data[key]
    }
    
    public func getKeys() -> [String]{
        var keys = [String]()
        for (key, _ ) in self.JSONValue {
            keys.append(key)
        }
        keys = keys.sort(<)
        return keys
    }
    
    deinit {
        self.BSONRAW.destroy()
    }
}

public func == (lhs: MongoDocument, rhs: MongoDocument) -> Bool {
    
    return (lhs.data as! [String : NSObject]) == (rhs.data as! [String : NSObject])
}

public func != (lhs: MongoDocument, rhs: MongoDocument) -> Bool {
    return !(lhs == rhs)
}

public func != (lhs: DocumentData, rhs: DocumentData) -> Bool {
    return !(lhs == rhs)
}

public func == (lhs: DocumentData, rhs: DocumentData) -> Bool {
    
    // if they're of different sizes
    if lhs.count != rhs.count {
        return false
    }
    
    
    // only need to check from one side because they're the same size - if something doesn't match then they aren't equal.
    // check that rhs contains all of lhs
    for (lhkey, lhvalue) in lhs {
        
        let lhval = lhvalue as! NSObject
        
        // casting into nsobject
        if let rhval = rhs[lhkey] as? NSObject {
            
            // if they're not the same, return false
            if rhval != lhval {
                return false
            }
        }
    }
    
    return true
}
