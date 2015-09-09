////
////  MongoDocument.swift
////  swiftMongoDB
////
////  Created by Dan Appel on 8/20/15.
////  Copyright © 2015 Dan Appel. All rights reserved.
////

import SwiftyJSON

public class MongoDocument {

    let BSONRAW: _bson_ptr_mutable = bson_new()
    var JSONValue: String? {
        return JSON(self.data).rawString()
    }
    
    public var data: DocumentData {
        return self.documentData
    }

    private var documentData = DocumentData()
    
    private func initBSON() {
        try! MongoBSONEncoder(data: data).copyTo(self.BSONRAW)
    }

    public init(data: DocumentData) {
        self.documentData = data
        self.initBSON()
    }

    public init(JSON: String) throws {

        guard let data = JSON.parseJSONDocumentData else {
            throw MongoError.CorruptDocument
        }

        self.documentData = data
        self.initBSON()
    }
    
    public init(withSchemaObject object: MongoObject) {
        self.documentData = object.properties()
        
        self.initBSON()
    }

    deinit {
        // throws error when bson is not allocated due to bson being empty (it seems)
        if self.data.count > 0 {
            bson_destroy(self.BSONRAW)
        }
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