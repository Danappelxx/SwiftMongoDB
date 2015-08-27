//
//  MongoCursor.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation
import mongo_c_driver

// MARK: - Cursor
public class MongoCursor {
    
    internal var cursor = mongo_cursor_alloc()
    
    public init(mongodb: MongoDB, collection: MongoCollection) {
        mongo_cursor_init(self.cursor, mongodb.connection!, collection.identifier)
    }
    
    internal init(connection: UnsafeMutablePointer<mongo>, collection: MongoCollection) {
        mongo_cursor_init(self.cursor, connection, collection.identifier)
    }
    
    deinit {
        mongo_cursor_destroy(cursor)
    }
    
    
    internal var nextIsOk: Bool {
        return (mongo_cursor_next(self.cursor) == MONGO_OK)
    }
    
    internal var currentBSON: UnsafePointer<bson> {
        return withUnsafePointer(&self.cursor.memory.current) { (bsonPtr) -> UnsafePointer<bson> in
            return bsonPtr
        }
    }
    
    public var current: MongoDocument {
        return MongoDocument(BSON: &self.cursor.memory.current)
    }
    
    internal var query: UnsafeMutablePointer<bson>? {
        didSet {
            mongo_cursor_set_query( self.cursor, self.query! );
            print("did set query")
        }
    }
    
    private var BSON: UnsafePointer<bson> {
        return mongo_cursor_bson(self.cursor)
    }
}