//
//  MongoDocument.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation
import mongo_c_driver

// MARK: - MongoDocument
public typealias DocumentData = [String : AnyObject]

public func == (lhs: MongoDocument, rhs: MongoDocument) -> Bool {

    return (lhs.data as! [String : NSObject]) == (rhs.data as! [String : NSObject])    
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


public class MongoDocument {
    
    internal let BSONValue = bson_alloc()
    public var data: DocumentData
    
    public init(data: DocumentData) {
        
        let objectId = MongoBSON.generateObjectId()
        self.id = objectId

        let mongoBSON = MongoBSON(data: data, withObjectId: objectId)
        mongoBSON.copyTo(self.BSONValue)
        //        bson_copy(self.BSONValue, mongoBSON.BSONValue)
        //        self.bsonValue = mongobson.BSONValue
        self.data = mongoBSON.data
    }
    
    internal init(BSON: UnsafeMutablePointer<bson>) {
        bson_copy(self.BSONValue, BSON)

        self.id = MongoBSON.getObjectIdFromBSON(BSON)
        self.data = MongoBSON.getDataFromBSON(BSON)
        
        bson_destroy(BSON)
    }
    
    public func printSelf() {
        bson_print(self.BSONValue)
    }

    deinit {
        bson_destroy(self.BSONValue)
    }

    //MARK: - Properties
    public let id: String?

    //    public var stringValue: String {
    //        bson_print(<#T##b: UnsafePointer<bson>##UnsafePointer<bson>#>)
    //    }
}
