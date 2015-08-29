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

public class MongoDocument {
    
    /// The raw BSON value of the document.
    internal let BSONValue = bson_alloc()
    
    /// The DocumentData form of the BSON value of the document.
    public var data: DocumentData
    
    
    /**
    Initializes a MongoDocument containing the given data.
    
    - parameter data: A parameter of type DocumentData which is the data that the document will contain.
    */
    public init(data: DocumentData) {
        
        let objectId = MongoBSON.generateObjectId()
        self.id = objectId

        let mongoBSON = MongoBSON(data: data, withObjectId: objectId)
        mongoBSON.copyTo(self.BSONValue)
        //        bson_copy(self.BSONValue, mongoBSON.BSONValue)
        //        self.bsonValue = mongobson.BSONValue
        self.data = mongoBSON.data
    }
    
    /**
    Initializes a MongoDocument containg the given BSON data. Automatically transcribed to DocumentData upon initialization.
    
    - parameter BSON: The raw BSON value of the document.
    */
    internal init(BSON: UnsafeMutablePointer<bson>) {
        bson_copy(self.BSONValue, BSON)

        self.id = MongoBSON.getObjectIdFromBSON(BSON)
        self.data = MongoBSON.getDataFromBSON(BSON)
        
        bson_destroy(BSON)
    }

    /**
    Initializes a MongoDocument containing the properties of the MongoObject. Properties starting with an underscore (_) will be ignored.
    
    - parameter schema: An object which conforms to protocol MongoObject.
    
    - returns: Returns an initialized MongoDocument.
    */
    convenience init(withSchemaObject schema: MongoObject) {
        self.init(data: schema.properties())
    }

    /**
    Prints the BSON value of self.
    */
    internal func printSelf() {
        bson_print(self.BSONValue)
    }

    /**
    Destroys the raw BSON value upon deinitialization.
    */
    deinit {
        bson_destroy(self.BSONValue)
    }

    /// The object id of the document.
    public let id: String?
}

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
