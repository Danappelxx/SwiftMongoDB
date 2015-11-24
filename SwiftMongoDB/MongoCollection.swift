//
//  MongoCollection.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import mongoc

public class MongoCollection {

    public let name: String
    public let databaseName: String

    let collectionRaw: _mongoc_collection

    convenience public init(name: String, database: MongoDatabase) {

        let ptr = mongoc_database_get_collection(database.databaseRaw, name)
        self.init(name: name, databaseName: database.name, ptr: ptr)
    }
    
    init(name: String, databaseName: String, ptr: _mongoc_collection) {
        self.name = name
        self.databaseName = databaseName
        self.collectionRaw = ptr
    }
    

    deinit {
        mongoc_collection_destroy(self.collectionRaw)
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

        var bson = try MongoBSON(data: document.data).bson
        
        var bsonError = bson_error_t()

        mongoc_collection_insert(self.collectionRaw, insertFlags, &bson, nil, &bsonError)
        
        try bsonError.throwIfError()
    }
    
    public func insert(document: DocumentData, flags: InsertFlags = InsertFlags.None) throws {

        try self.insert(MongoDocument(data: document), flags: flags)
    }
    
    public func renameCollectionTo(newName : String) throws{
        var bsonError = bson_error_t()
        mongoc_collection_rename(self.collectionRaw, databaseName, newName, false, &bsonError)
        
        try bsonError.throwIfError()
    }
    
    public func find(query: DocumentData = DocumentData(), flags: QueryFlags = QueryFlags.None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0) throws -> [MongoDocument] {

        var query = try MongoBSON(data: query).bson

        // standard options - should be customizable later on
        let cursor = MongoCursor(
            collection: self,
            operation: .Find,
            query: &query,
            options: (
                queryFlags: flags.rawFlag,
                skip: skip,
                limit: limit,
                batchSize: batchSize
            )
        )

        let documents = try cursor.getDocuments()

        if cursor.lastError.isError {
            throw cursor.lastError
        }

        return documents
    }
    
    public func findOne(query: DocumentData = DocumentData(), flags: QueryFlags = QueryFlags.None, skip: Int = 0, batchSize: Int = 0) throws -> MongoDocument? {

        let doc = try find(query, flags: flags, skip: skip, limit: 1, batchSize: batchSize)

        if doc.count == 0 {
            return nil
        } else {
            return doc[0]
        }
    }

    public func update(query: DocumentData = DocumentData(), newValue: DocumentData, flags: UpdateFlags = UpdateFlags.None) throws -> Bool {

        var query = try MongoBSON(data: query).bson

        var document = try MongoBSON(data: newValue).bson

        var error = bson_error_t()
        let success = mongoc_collection_update(self.collectionRaw, flags.rawFlag, &query, &document, nil, &error)

        try error.throwIfError()

        return success
    }


    public func remove(query: DocumentData = DocumentData(), flags: RemoveFlags = RemoveFlags.None) throws -> Bool {

        var query = try MongoBSON(data: query).bson

        var error = bson_error_t()
        let success = mongoc_collection_remove(self.collectionRaw, flags.rawFlag, &query, nil, &error)

        try error.throwIfError()

        return success
    }
    
    public func performBasicCollectionCommand(command: DocumentData) throws -> DocumentData {
        
        var command = try MongoBSON(data: command).bson
        
        var reply = bson_t()
        var error = bson_error_t()
        
        mongoc_collection_command_simple(self.collectionRaw, &command, nil, &reply, &error)

        try error.throwIfError()

        return try MongoBSON(bson: reply).data
//        mongoc_collection_command_simple(collection: COpaquePointer, command: UnsafePointer<bson_t>, read_prefs: COpaquePointer, reply: UnsafeMutablePointer<bson_t>, error: UnsafeMutablePointer<bson_error_t>)
    }
}
