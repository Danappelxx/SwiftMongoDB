//
//  Collection.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import CMongoC
import BinaryJSON

public final class Collection {

    public let name: String
    public let databaseName: String

    let pointer: _mongoc_collection

    public init(database: Database, name: String) {
        let pointer = mongoc_database_get_collection(database.pointer, name)
        self.name = name
        self.databaseName = database.name
        self.pointer = pointer
    }

    deinit {
        mongoc_collection_destroy(self.pointer)
    }

    public func insert(document: BSON.Document, flags: InsertFlags = .None) throws {

        let document = try BSON.AutoReleasingCarrier(document: document)
        var error = bson_error_t()

        mongoc_collection_insert(self.pointer, flags.rawFlag, document.pointer, nil, &error)

        try error.throwIfError()
    }

    public func renameCollection(to newName: String) throws {
        var error = bson_error_t()
        mongoc_collection_rename(self.pointer, databaseName, newName, false, &error)

        try error.throwIfError()
    }

    public func find(query query: BSON.Document = BSON.Document(), fields: BSON.Array? = nil, flags: QueryFlags = .None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0) throws -> Cursor {

        let query = try BSON.AutoReleasingCarrier(document: query)

        let cursorPointer = mongoc_collection_find(
            self.pointer,
            flags.rawFlag,
            skip.UInt32Value,
            limit.UInt32Value,
            batchSize.UInt32Value,
            query.pointer,
            nil, // fields
            nil // read prefs
        )

        let cursor = Cursor(pointer: cursorPointer)

        return cursor
    }

    public func update(query query: BSON.Document, newValue: BSON.Document, flags: UpdateFlags = .None) throws -> Bool {

        let query = try BSON.AutoReleasingCarrier(document: query)
        let document = try BSON.AutoReleasingCarrier(document: newValue)

        var error = bson_error_t()

        let success = mongoc_collection_update(
            self.pointer,
            flags.rawFlag,
            query.pointer,
            document.pointer,
            nil,
            &error
        )

        try error.throwIfError()

        return success
    }


    public func remove(query query: BSON.Document = BSON.Document(), flags: RemoveFlags = .None) throws -> Bool {

        let query = try BSON.AutoReleasingCarrier(document: query)

        var error = bson_error_t()

        let success = mongoc_collection_remove(
            self.pointer,
            flags.rawFlag,
            query.pointer,
            nil,
            &error
        )

        try error.throwIfError()

        return success
    }

    public func save(document document: BSON.Document) throws -> Bool {

        let document = try BSON.AutoReleasingCarrier(document: document)

        var error = bson_error_t()

        let success = mongoc_collection_save(pointer, document.pointer, nil, &error)

        try error.throwIfError()

        return success
    }

    public func basicCommand(command command: BSON.Document) throws -> BSON.Document {

        let command = try BSON.AutoReleasingCarrier(document: command)

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_collection_command_simple(self.pointer, command.pointer, nil, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }
        return res
    }

    public func destroy() {
        mongoc_collection_destroy(pointer)
    }

//    public func performCommand(command: BSON.Document, flags: QueryFlags, options: QueryOptions, fields: [String]) throws -> Cursor {
//
//        guard let fieldsJSON = fields.toJSON()?.toString() else { throw MongoError.InvalidData }
//
//        var command = try MongoBSON(data: command).bson
//        var fields = try MongoBSON(json: fieldsJSON).bson
//
//        let cursor = mongoc_collection_command(pointer, flags.rawFlag, options.skip.UInt32Value, options.limit.UInt32Value, options.batchSize.UInt32Value, &command, &fields, nil)
//
//        return Cursor(cursor: cursor)
//    }

    public func count(query query: BSON.Document = BSON.Document(), flags: QueryFlags = .None, skip: Int = 0, limit: Int = 0) throws -> Int {

        let query = try BSON.AutoReleasingCarrier(document: query)

        var error = bson_error_t()

        let count = mongoc_collection_count(
            self.pointer,
            flags.rawFlag,
            query.pointer,
            Int64(skip),
            Int64(limit),
            nil,
            &error
        )

        try error.throwIfError()

        return Int(count)
    }

    public func drop() throws {

        var error = bson_error_t()

        mongoc_collection_drop(pointer, &error)

        try error.throwIfError()
    }

    public func rename(newDatabaseName newDatabaseName: String, newCollectionName: String, dropBeforeRename: Bool) throws -> Bool {

        var error = bson_error_t()

        let success = mongoc_collection_rename(pointer, newDatabaseName, newCollectionName, dropBeforeRename, &error)

        try error.throwIfError()

        return success
    }

    public func stats(options options: BSON.Document) throws -> BSON.Document {

        let options = try BSON.AutoReleasingCarrier(document: options)

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_collection_stats(self.pointer, options.pointer, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }
        return res
    }

    public func validate(options options: BSON.Document) throws -> BSON.Document {

        let options = try BSON.AutoReleasingCarrier(document: options)

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_collection_validate(self.pointer, options.pointer, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }

        return res
    }

    // TODO
    //func mongoc_collection_find_and_modify(collection: OpaquePointer, _ query: UnsafePointer<bson_t>, _ sort: UnsafePointer<bson_t>, _ update: UnsafePointer<bson_t>, _ fields: UnsafePointer<bson_t>, _ _remove: Bool, _ upsert: Bool, _ _new: Bool, _ reply: UnsafeMutablePointer<bson_t>, _ error: UnsafeMutablePointer<bson_error_t>) -> Bool
}
