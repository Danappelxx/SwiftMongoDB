//
//  MongoCollection.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation
import mongo_c_driver

// MARK: - MongoCollection
public class MongoCollection {
    
    internal var connection: UnsafeMutablePointer<mongo>!
    
    internal var identifier: String {
        return "\(self.databaseName).\(self.name)"
    }
    internal var databaseName: String!
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
    
    //    public var cursor: MongoCursor {
    //        return MongoCursor(connection: self.connection, collection: self)
    //    }
    
    public func cursor() -> MongoCursor {
        return MongoCursor(connection: self.connection, collection: self)
    }
    
    //    public func query(query: DocumentData) -> MongoQuery {
    //
    //        return MongoQuery(query: query, connection: self.connection, collection: self)
    //    }
    //    public var query: MongoQuery {
    //        return MongoQuery(connection: self.connection, collection: self)
    //        return MongoQuery(data:
    //    }
    
    
    public func insert(data: MongoDocument) {
        
        if self.connection == nil {
            print("didn't register collection")
            return
        }
        
        let mwc = mongo_write_concern_alloc()
        mongo_insert(self.connection, self.identifier, data.BSONValue, mongo_write_concern_alloc())
        mongo_write_concern_dealloc(mwc)
    }
    
    public func remove(queryData: DocumentData) {
        
        if self.connection == nil {
            return
        }
        
        let query = bson_alloc()
        let mongoBSON = MongoBSON(data: queryData, includeObjectId: false)
        mongoBSON.copyTo(query)
        
        let mwc = mongo_write_concern_alloc()
        mongo_remove(self.connection, self.identifier, query, mwc)
        
    }
    
    public func update(query: DocumentData, document: MongoDocument) {
        
        if self.connection == nil {
            return
        }
        
    }
    
    public func findAll() -> MongoResult<[MongoDocument]> {
        
        if self.connection == nil {
            return MongoResult.Failure(MongoError().error)
        }
        
        let cursor = MongoCursor(connection: self.connection, collection: self)
        
        var results: [MongoDocument] = []
        while cursor.nextIsOk {
            results.append(cursor.current)
        }
        
        return MongoResult.Success(results)
    }
    
    public func first(queryData: DocumentData?) -> MongoResult<MongoDocument> {
        
        if self.connection == nil {
            return MongoResult.Failure(MongoError().error)
        }
        
        let cursor = self.cursor()
        
        // refer to find() for an explanation of this snippet
        if let queryData = queryData {
            
            let mongoBSON = MongoBSON(data: queryData, includeObjectId: false)
            
            let query = bson_alloc()
            mongoBSON.copyTo(query)
            
            cursor.query = query
        }
        
        if cursor.nextIsOk {
            return MongoResult.Success(cursor.current)
        }
        
        return MongoResult.Failure(MongoError().error)
    }
    
    public func find(queryData: DocumentData? = nil) -> MongoResult<[MongoDocument]> {
        
        if self.connection == nil {
            return MongoResult.Failure(MongoError().error)
        }
        
        
        let cursor = self.cursor()
        
        // if query isn't blank (should be acceptable to not have query)
        if let queryData = queryData {
            
            // parse the query data into bson
            let mongoBSON = MongoBSON(data: queryData, includeObjectId: false)
            
            let query = bson_alloc()
            mongoBSON.copyTo(query)
            // this copy step is required for whatever reason - without it everything breaks
            
            // cursor.query has a didSet where it gets bound to the actual cursor properly
            cursor.query = query
        }
        
        
        var results: [MongoDocument] = []
        
        // loops through all the query results, appends them to array
        while cursor.nextIsOk {
            results.append(cursor.current)
        }
        
        return MongoResult.Success(results)
    }
}

extension MongoCollection: Hashable {
    public var hashValue: Int {
        return self.name.hashValue
    }
}

public func == (lhs: MongoCollection, rhs: MongoCollection) -> Bool {
    return lhs.name == rhs.name
}
extension MongoCollection: Equatable {}
