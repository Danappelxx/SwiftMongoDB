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
        let mongoBSON = MongoBSON(data: queryData)
        mongoBSON.copyTo(query)
        
        let mwc = mongo_write_concern_alloc()
        mongo_remove(self.connection, self.identifier, query, mwc)
        
    }

    
    public enum UpdateType {
        case Basic
        case Upsert
        case Multi
    }
    
    /**
    Updates the documents matched by the with the given modifications.
    
    - parameter query:The query in the form of DocumentData ( [String : AnyObject] )
    - parameter modifications:The modifications applied to the matched object(s). Also in the form of DocumentData.
    - parameter type:The type of update to be performed. Valid options are .Basic, .Upsert, .Multi
    */
    public func update(query query: DocumentData, data: DocumentData, type: UpdateType) -> MongoResult<MongoDocument> {

        if self.connection == nil {
            return MongoResult.Failure(MongoError().error)
        }

        let queryBSON = MongoBSON(data: query)
        let dataBSON = MongoBSON(data: data)

        let queryBSONRaw = bson_alloc()
        let dataBSONRaw = bson_alloc()
        queryBSON.copyTo(queryBSONRaw)
        dataBSON.copyTo(dataBSONRaw)


        let updateType: UInt32
        switch type {
        case .Basic:
            updateType = MONGO_UPDATE_BASIC.rawValue
        case .Upsert:
            updateType = MONGO_UPDATE_UPSERT.rawValue
        case .Multi:
            updateType = MONGO_UPDATE_MULTI.rawValue
        }


        let mwc = mongo_write_concern_alloc()
        mongo_update(self.connection, self.identifier, queryBSONRaw, dataBSONRaw, Int32(updateType), mwc)
        
        return MongoResult.Success(MongoDocument(data: data))

    }

    public func update(query query: DocumentData, data: MongoDocument, type: UpdateType) {
        self.update(query: query, data: data.data!, type: type)
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
            
            let mongoBSON = MongoBSON(data: queryData)
            
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
            let mongoBSON = MongoBSON(data: queryData)
            
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
