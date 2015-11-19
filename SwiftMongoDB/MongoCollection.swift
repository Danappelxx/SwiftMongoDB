//
//  MongoCollection.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import mongoc

public class MongoCollection {

    public let client: MongoClient
    public let collectionName: String

    let clientRAW: _mongoc_client
    let collectionRAW: _mongoc_collection

    public init(collectionName: String, client: MongoClient) {

        self.client = client
        self.clientRAW = client.clientRAW

        self.collectionName = collectionName

        self.collectionRAW = mongoc_client_get_collection(self.clientRAW, self.client.databaseName, self.collectionName)

    }

    deinit {
        mongoc_collection_destroy(self.collectionRAW)
    }

    private func cursor(operation operation: MongoCursorOperation, query: _bson_ptr_mutable, options: (queryFlags: mongoc_query_flags_t, skip: Int, limit: Int, batchSize: Int)) -> MongoCursor {

        // ugh so ugly
        return MongoCursor(collection: self, operation: operation, query: query, options: (queryFlags: options.queryFlags, skip: options.skip, limit: options.limit, batchSize: options.batchSize))
    }

    public enum InsertFlags {
        case None
        case ContinueOnError
    }

    public func insert(document: MongoDocument, flags: InsertFlags = InsertFlags.None) throws {

        let insertFlags: mongoc_insert_flags_t
        switch flags {
        case .None: insertFlags = MONGOC_INSERT_NONE
        case .ContinueOnError: insertFlags = MONGOC_INSERT_CONTINUE_ON_ERROR
        }

        var bsonError = bson_error_t()

        mongoc_collection_insert(self.collectionRAW, insertFlags, document.BSONRAW, nil, &bsonError)

        if bsonError.error.isError {
            throw bsonError.error
        }
    }
    
    public func insert(document: DocumentData, flags: InsertFlags = InsertFlags.None) throws {

        try self.insert(MongoDocument(data: document), flags: flags)
    }
    
    public func renameCollectionTo(newName : String) throws{
        var bsonError = bson_error_t()
        mongoc_collection_rename(self.collectionRAW, client.databaseName, newName, false, &bsonError)
        if bsonError.error.isError {
            throw bsonError.error
        }
    }
    
    public func find(query: DocumentData = DocumentData(), flags: QueryFlags = QueryFlags.None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0) throws -> [MongoDocument] {

        var queryBSON = bson_t()
        try! MongoBSONEncoder(data: query).copyTo(&queryBSON)



        // standard options - should be customizable later on
        let cursor = self.cursor(operation: .Find, query: &queryBSON, options: (queryFlags: flags.rawFlag, skip: skip, limit: limit, batchSize: batchSize))

        var outputDocuments = [MongoDocument]()

        while cursor.nextIsOK {
            guard let nextDocument = cursor.nextDocument else {
                throw MongoError.CorruptDocument
            }
            outputDocuments.append(nextDocument)
        }
        
        if cursor.lastError.isError {
            throw cursor.lastError
        }

        return outputDocuments
    }
    
    public func findOne(query: DocumentData = DocumentData(), flags: QueryFlags = QueryFlags.None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0) throws -> MongoDocument? {
        
        let queryBSON = try! MongoBSONEncoder(data: query).BSONRAW
        
        let queryFlags: mongoc_query_flags_t = flags.rawFlag
        
        // standard options - should be customizable later on
        let cursor = self.cursor(operation: .Find, query: queryBSON, options: (queryFlags: queryFlags, skip: skip, limit: skip, batchSize: skip))
        
        if cursor.nextIsOK {
            
            guard let nextDocument = cursor.nextDocument else {
                throw MongoError.CorruptDocument
            }
            
            return nextDocument
        }
        
        return nil
    }

    public enum UpdateFlags {
        case None
        case Upsert
        case MultiUpdate

        internal var rawFlag: mongoc_update_flags_t {
            switch self {
            case .None: return MONGOC_UPDATE_NONE
            case .Upsert: return MONGOC_UPDATE_UPSERT
            case .MultiUpdate: return MONGOC_UPDATE_MULTI_UPDATE
            }
        }
    }

    public func update(query: DocumentData = DocumentData(), newValue: DocumentData, flags: UpdateFlags = UpdateFlags.None) throws -> Bool {

        let updateFlags: mongoc_update_flags_t = flags.rawFlag

        var queryBSON = bson_t()
        try MongoBSONEncoder(data: query).copyTo(&queryBSON)

        var documentBSON = bson_t()
        try MongoBSONEncoder(data: newValue).copyTo(&documentBSON)

        var error = bson_error_t()
        let success = mongoc_collection_update(self.collectionRAW, updateFlags, &queryBSON, &documentBSON, nil, &error)

        if error.error.isError {
            throw error.error
        }

        return success
    }

    public enum RemoveFlags {
        case None
        case SingleRemove
    }

    public func remove(query: DocumentData = DocumentData(), flags: RemoveFlags = RemoveFlags.None) throws -> Bool {

        let removeFlags: mongoc_remove_flags_t
        switch flags {
        case .None: removeFlags = MONGOC_REMOVE_NONE; break
        case .SingleRemove: removeFlags = MONGOC_REMOVE_SINGLE_REMOVE; break
        }

        var queryBSON = bson_t()
        try! MongoBSONEncoder(data: query).copyTo(&queryBSON)

        var error = bson_error_t()
        let success = mongoc_collection_remove(self.collectionRAW, removeFlags, &queryBSON, nil, &error)

        if error.error.isError {
            throw error.error
        }

        return success
    }
    
    public func performBasicCollectionCommand(command: DocumentData) throws -> DocumentData {
        
        var commandRAW = bson_t()
        try MongoBSONEncoder(data: command).copyTo(&commandRAW)
        
        var reply = bson_t()
        var error = bson_error_t()
        
        mongoc_collection_command_simple(self.collectionRAW, &commandRAW, nil, &reply, &error)

        if error.error.isError {
            throw error.error
        }

        return try MongoBSONDecoder(BSON: &reply).result.data
//        mongoc_collection_command_simple(collection: COpaquePointer, command: UnsafePointer<bson_t>, read_prefs: COpaquePointer, reply: UnsafeMutablePointer<bson_t>, error: UnsafeMutablePointer<bson_error_t>)
    }
}
