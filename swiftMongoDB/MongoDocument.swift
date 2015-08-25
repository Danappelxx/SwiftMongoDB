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
public typealias DocumentData = [String:AnyObject]

public class MongoDocument {
    
    internal let BSONValue = bson_alloc()
    public var data: DocumentData?
    
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
    }
    
    public func printSelf() {
        bson_print(self.BSONValue)
    }

    deinit {
        bson_destroy(self.BSONValue)
    }

    //MARK: - Properties
    public let id: String

    //    public var stringValue: String {
    //        bson_print(<#T##b: UnsafePointer<bson>##UnsafePointer<bson>#>)
    //    }
}
