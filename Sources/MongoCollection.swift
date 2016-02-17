//
//  MongoCollection.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

// #if os(Linux)
import CMongoC
// #else
// import mongoc
// #endif
// import SwiftFoundation
import BinaryJSON

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

    public func insert(document: MongoDocument, flags: InsertFlags = InsertFlags.None) throws {

        let document = document.bson
        var error = bson_error_t()

        mongoc_collection_insert(self.collectionRaw, flags.rawFlag, document, nil, &error)

        try error.throwIfError()
    }

    public func insert(document: DocumentData, flags: InsertFlags = InsertFlags.None) throws {

        try self.insert(MongoDocument(data: document), flags: flags)
    }

    public func renameCollectionTo(newName : String) throws {
        var error = bson_error_t()
        mongoc_collection_rename(self.collectionRaw, databaseName, newName, false, &error)

        try error.throwIfError()
    }

    public func find(query: DocumentData = DocumentData(), flags: QueryFlags = QueryFlags.None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0) throws -> [MongoDocument] {

        let query = try MongoDocument(data: query).bson

        // standard options - should be customizable later on
        let cursor = MongoCursor(
            collection: self,
            operation: .Find,
            query: query,
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

        let query = try MongoDocument(data: query).bson

        let document = try MongoDocument(data: newValue).bson

        var error = bson_error_t()
        let success = mongoc_collection_update(self.collectionRaw, flags.rawFlag, query, document, nil, &error)

        try error.throwIfError()

        return success
    }


    public func remove(query: DocumentData = DocumentData(), flags: RemoveFlags = RemoveFlags.None) throws -> Bool {

        let query = try MongoDocument(data: query).bson

        var error = bson_error_t()
        let success = mongoc_collection_remove(self.collectionRaw, flags.rawFlag, query, nil, &error)

        try error.throwIfError()

        return success
    }

    public func save(document: DocumentData) throws -> Bool {

        let document = try MongoDocument(data: document).bson
        var error = bson_error_t()

        let success = mongoc_collection_save(collectionRaw, document, nil, &error)

        try error.throwIfError()

        return success
    }

    public func performBasicCollectionCommand(command: DocumentData) throws -> DocumentData {

        let command = try MongoDocument(data: command).bson

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_collection_command_simple(self.collectionRaw, command, nil, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }
        return res
    }

    public func destroy() {
        mongoc_collection_destroy(collectionRaw)
    }

//    public func performCommand(command: DocumentData, flags: QueryFlags, options: QueryOptions, fields: [String]) throws -> MongoCursor {
//
//        guard let fieldsJSON = fields.toJSON()?.toString() else { throw MongoError.InvalidData }
//
//        var command = try MongoBSON(data: command).bson
//        var fields = try MongoBSON(json: fieldsJSON).bson
//
//        let cursor = mongoc_collection_command(collectionRaw, flags.rawFlag, options.skip.UInt32Value, options.limit.UInt32Value, options.batchSize.UInt32Value, &command, &fields, nil)
//
//        return MongoCursor(cursor: cursor)
//    }

    public func count(query: DocumentData, flags: QueryFlags, skip: Int, limit: Int) throws -> Int {

        let query = try MongoDocument(data: query).bson

        var error = bson_error_t()

        let count = mongoc_collection_count(collectionRaw, flags.rawFlag, query, Int64(skip), Int64(limit), nil, &error)

        try error.throwIfError()

        return Int(count)
    }

    public func drop() throws {

        var error = bson_error_t()

        mongoc_collection_drop(collectionRaw, &error)

        try error.throwIfError()
    }

    public func rename(newDatabase: String, newCollection: String, dropBeforeRename: Bool) throws -> Bool {

        var error = bson_error_t()

        let success = mongoc_collection_rename(collectionRaw, newDatabase, newCollection, dropBeforeRename, &error)

        try error.throwIfError()

        return success
    }

    public func stats(options: DocumentData) throws -> DocumentData {

        let options = try MongoDocument(data: options).bson

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_collection_stats(collectionRaw, options, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }
        return res
    }

    public func validate(options: DocumentData) throws -> DocumentData {
        let options = try MongoDocument(data: options).bson

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_collection_validate(collectionRaw, options, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }
        return res
    }

    // TODO
    //func mongoc_collection_find_and_modify(collection: COpaquePointer, _ query: UnsafePointer<bson_t>, _ sort: UnsafePointer<bson_t>, _ update: UnsafePointer<bson_t>, _ fields: UnsafePointer<bson_t>, _ _remove: Bool, _ upsert: Bool, _ _new: Bool, _ reply: UnsafeMutablePointer<bson_t>, _ error: UnsafeMutablePointer<bson_error_t>) -> Bool
}
