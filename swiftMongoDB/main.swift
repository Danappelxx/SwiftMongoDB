//
//  main.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/14/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

import mongo_c_driver

//public typealias MongoResultSuccess = (results: [AnyObject]) -> ()
//public typealias MongoResultError = ((error: AnyObject) -> ())
//public enum MongoResult {
//
//    case Success = MongoResultSuccess
//    case Error = MongoResultError
//}

public class MongoError: ErrorType {}

// MARK: - MongoDB
public class MongoDB {

    private var connection = mongo_alloc()

    public var databaseName: String
    private var collections = Set<MongoCollection>()

    /**
    Initiates a mongodb connection to the given host and ports.
    */
    public init(host: UnsafePointer<Int8>, port: Int, database: String) {

        mongo_init(self.connection)

        let status = mongo_client(self.connection, host, Int32(port))

        if status != MONGO_OK {
            print("shitshitshit")
        }

        self.databaseName = database
    }

    /**
    Initates the mongodb connection to the default host and port (usually localhost:27017)
    */
    public convenience init(database: String) {

        self.init(host: Helpers.getIPAddress(), port: 27017, database: database)

    }

    /**
    Deallocates the mongo connection
    */
    deinit {
        mongo_destroy(self.connection)
    }

    public enum ConnectionStatus: String {
        case Success = "Successful connection"
        case NoSocket = "No socket"
        case Fail = "Connection fail"
        case NotMaster = "Not master"
        
        case Unexpected = "Unexpected error"
    }
    
    /// Returns the status of the mongodb connection
    public var connectionStatus: ConnectionStatus {
        
        switch connection.memory.err.rawValue {

        case MONGO_CONN_SUCCESS.rawValue:
            return ConnectionStatus.Success
            
        case MONGO_CONN_NO_SOCKET.rawValue:
            return ConnectionStatus.NoSocket
            
        case MONGO_CONN_FAIL.rawValue:
            return ConnectionStatus.Fail
            
        case MONGO_CONN_NOT_MASTER.rawValue:
            return ConnectionStatus.NotMaster
            
        default:
            return ConnectionStatus.Unexpected
            
        }
    }
    
    public func registerCollection(collection: MongoCollection) {

        collection.connection = self.connection
        collection.databaseName = self.databaseName

        self.collections.insert(collection)
    }
}

// MARK: - MongoDocument
public typealias DocumentData = [String:AnyObject]

public class MongoDocument {

    private let BSONValue = bson_alloc()
    public var data: DocumentData?

    public init(data: DocumentData) {

        let mongoBSON = MongoBSON(data: data)
        mongoBSON.copyTo(self.BSONValue)
//        bson_copy(self.BSONValue, mongoBSON.BSONValue)
//        self.bsonValue = mongobson.BSONValue
        self.data = mongoBSON.data
    }
    
    private init(BSON: UnsafeMutablePointer<bson>) {
        bson_copy(self.BSONValue, BSON)
    }
    
    public func printSelf() {
        bson_print(self.BSONValue)
    }

    deinit {
        bson_destroy(self.BSONValue)
    }
    
//    public var stringValue: String {
//        bson_print(<#T##b: UnsafePointer<bson>##UnsafePointer<bson>#>)
//    }
}

// MARK: - MongoCollection
public class MongoCollection {

    private var connection: UnsafeMutablePointer<mongo>!

    private var identifier: String {
        return "\(self.databaseName).\(self.name)"
    }
    private var databaseName: String!
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

    public func remove(query: DocumentData) {

        if self.connection == nil {
            return
        }
        
//        let mwc = mongo_write_concern_alloc()
//        mongo_remove(self.connection, self.fullName, cond: UnsafePointer<bson>, mwc)

    }
    
    public func update(query: DocumentData, document: MongoDocument) {

        if self.connection == nil {
            return
        }

    }
    
    public func findAll() -> [MongoDocument]? {

        if self.connection == nil {
            return nil
        }

        let cursor = MongoCursor(connection: self.connection, collection: self)

        var results: [MongoDocument] = []
        while cursor.nextIsOk {
            results.append(cursor.current)
        }

        return results
    }
    
    public func first() -> MongoDocument? {

        if self.connection == nil {
            return nil
        }

        let cursor = MongoCursor(connection: self.connection, collection: self)

        if cursor.nextIsOk {
            return cursor.current
        }

        return nil
    }

    public func find(queryData: DocumentData? = nil) -> [MongoDocument]? {

        if self.connection == nil {
            return nil
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
        

        if results.count > 0 {
            return results
        }

        return nil
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

// MARK: - Cursor
public class MongoCursor {

    private var cursor = mongo_cursor_alloc()

    public init(mongodb: MongoDB, collection: MongoCollection) {
        mongo_cursor_init(self.cursor, mongodb.connection, collection.identifier)
    }

    private init(connection: UnsafeMutablePointer<mongo>, collection: MongoCollection) {
        mongo_cursor_init(self.cursor, connection, collection.identifier)
    }

    deinit {
        mongo_cursor_destroy(cursor)
    }



    private var next: Int32 {
        return mongo_cursor_next(self.cursor)
    }

    private var nextIsOk: Bool {
        return self.next == MONGO_OK
    }

    private var currentBSON: UnsafePointer<bson> {
        return withUnsafePointer(&self.cursor.memory.current) { (bsonPtr) -> UnsafePointer<bson> in
            return bsonPtr
        }
    }

    public var current: MongoDocument {
        return MongoDocument(BSON: &self.cursor.memory.current)
    }

    private var query: UnsafeMutablePointer<bson>? {
        didSet {
            mongo_cursor_set_query( self.cursor, self.query! );
            print("did set query")
        }
    }

    private var BSON: UnsafePointer<bson> {
        return mongo_cursor_bson(self.cursor)
    }
}


// MARK: - MongoBSON
private class MongoBSON {

    let BSONValue = bson_alloc()
    var data: DocumentData

    init(data: DocumentData, includeObjectId: Bool = true) {
        
        self.data = data

        // init bson
        bson_init(self.BSONValue)

        // add object id if necessary
        if includeObjectId {
            bson_append_new_oid(self.BSONValue, "_id")
            print("appended object id")
        }


        // go through each key:value pair and append it to the bson object
        for (key, value) in data {
            
            switch value {
                
            case let value as String:
                bson_append_string(self.BSONValue, key, value)
                print("appended string")
                break
            case let value as Int:
                bson_append_int(self.BSONValue, key, Int32(value))
                print("appended int")
                break
                //        case let value as Array:
                
            default:
                break
            }
            
//            self.processPair(key: key, value: value)
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

    // it appears as though using ints as keys might break shit
    func processPair(key key: String, value: AnyObject) {
        
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
            bson_append_start_array(self.BSONValue, key)

            // recursively creates array by calling processPair on each element in the array
            for (index, val) in value.enumerate() {
                self.processPair(key: index.description, value: val)
            }

            bson_append_finish_array(self.BSONValue)
            break
        case let value as [String:AnyObject]:
            bson_append_start_object(self.BSONValue, key)

            for (objectKey, objectVal) in value {
                self.processPair(key: objectKey, value: objectVal)
            }
            
            bson_append_finish_object(self.BSONValue)
            break

        default:
            break
        }
    }

    func copyTo(BSON: UnsafeMutablePointer<bson>) {
        bson_copy(BSON, self.BSONValue)
    }
}


//            {
//                name: "Kyle",
//
//                colors: [ "red", "blue", "green" ],
//
//                address: {
//                    city: "New York",
//                    zip: "10011-4567"
//                }
//            }
//            bson b[1];
//
//            bson_init( b );
//            bson_append_string( b, "name", "Kyle" );
//
//            bson_append_start_array( b, "colors" );
//            bson_append_string( b, "0", "red" );
//            bson_append_string( b, "1", "blue" );
//            bson_append_string( b, "2", "green" );
//            bson_append_finish_array( b );
//
//            bson_append_start_object( b, "address" );
//            bson_append_string( b, "city", "New York" );
//            bson_append_string( b, "zip", "10011-4567" );
//            bson_append_finish_object( b );
//
//            if( bson_finish( b ) != BSON_OK )
//            printf(" Error. ");