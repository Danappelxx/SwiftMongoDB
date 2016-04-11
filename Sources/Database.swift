//
//  Database.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 11/23/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import CMongoC
import BinaryJSON

public final class Database {

    let pointer: _mongoc_database

    /// Databases are automatically created on the MongoDB server upon insertion of the first document into a collection. There is no need to create a database manually.
    public init(client: Client, name: String) {
        self.pointer = mongoc_client_get_database(client.pointer, name)
    }

    deinit {
        mongoc_database_destroy(pointer)
    }

    public var name: String {
        let nameRaw = mongoc_database_get_name(pointer)
        return String(cString:nameRaw)
    }

    public var collectionNames: [String]? {
        var error = bson_error_t()

        var buffer = mongoc_database_get_collection_names(self.pointer, &error)

        if error.error.isError {
            return nil
        }

        var names = [String]()

        while buffer.pointee != nil {

            let name = String(cString:buffer.pointee)
            names.append(name)

            buffer = buffer.successor()
        }

        return names
    }

    public func removeUser(username: String) throws -> Bool {
        var error = bson_error_t()
        let successful = mongoc_database_remove_user(pointer, username, &error)

        try error.throwIfError()

        return successful
    }

    public func removeAllUsers() throws -> Bool {
        var error = bson_error_t()
        let successful = mongoc_database_remove_all_users(pointer, &error)

        try error.throwIfError()

        return successful
    }

//    public func addUser(username username: String, password: String, roles: [String], customData: BSON.Document) throws -> Bool {
//
//        guard let rolesJSON = roles.toJSON()?.toString() else { throw MongoError.InvalidData }
//
//        var error = bson_error_t()
//
//        var rolesRaw = try MongoBSON(json: rolesJSON).bson
//        var customDataRaw = try MongoBSON(data: customData).bson
//
//        let successful = mongoc_database_add_user(pointer, username, password, &rolesRaw, &customDataRaw, &error)
//
//        try error.throwIfError()
//
//        return successful
//    }

//    public func command(command: BSON.Document, flags: QueryFlags = .None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0, fields: [String] = []) throws -> Cursor {
//
//        guard let fieldsJSON = fields.toJSON()?.toString() else { throw MongoError.InvalidData }
//
//        var commandRaw = try MongoBSON(data: command).bson
//        var fieldsRaw = try MongoBSON(json: fieldsJSON).bson
//
//        let cursorRaw = mongoc_database_command(pointer, flags.rawFlag, skip.UInt32Value, limit.UInt32Value, batchSize.UInt32Value, &commandRaw, &fieldsRaw, nil)
//
//        let cursor = Cursor(cursor: cursorRaw)
//
//        return cursor
//    }

    public func drop() throws -> Bool {

        var error = bson_error_t()

        let successful = mongoc_database_drop(pointer, &error)

        try error.throwIfError()

        return successful
    }

    public func hasCollection(name name: String) throws -> Bool {

        var error = bson_error_t()

        let successful = mongoc_database_has_collection(pointer, name, &error)

        try error.throwIfError()

        return successful
    }

    public func createCollection(name name: String, options: BSON.Document) throws -> Collection {

        let options = try BSON.AutoReleasingCarrier(document: options)
        var error = bson_error_t()

        mongoc_database_create_collection(pointer, name, options.pointer, &error)

        try error.throwIfError()

        let collection = Collection(database: self, name: name)

        return collection
    }

    public func findCollections(filter filter: BSON.Document) throws -> Cursor {

        let filter = try BSON.AutoReleasingCarrier(document: filter)
        var error = bson_error_t()

        let cursorPointer = mongoc_database_find_collections(pointer, filter.pointer, &error)

        try error.throwIfError()

        let cursor = Cursor(pointer: cursorPointer)

        return cursor
    }

    public func basicCommand(command command: BSON.Document) throws -> BSON.Document {

        let command = try BSON.AutoReleasingCarrier(document: command)

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_database_command_simple(self.pointer, command.pointer, nil, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }

        return res
    }
}
