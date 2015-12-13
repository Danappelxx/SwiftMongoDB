//
//  MongoDatabase.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 11/23/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import CMongoC

public class MongoDatabase {

    let databaseRaw: _mongoc_database

    public init(client: MongoClient, name: String) {
        self.databaseRaw = mongoc_client_get_database(client.clientRaw, name)
    }

    init(client: MongoClient) {
        self.databaseRaw = mongoc_client_get_default_database(client.clientRaw)
    }

    public var name: String {
        let nameRaw = mongoc_database_get_name(databaseRaw)
        return String(UTF8String: nameRaw)!
    }

    public func removeUser(username: String) throws -> Bool {
        var error = bson_error_t()
        let successful = mongoc_database_remove_user(databaseRaw, username, &error)

        try error.throwIfError()

        return successful
    }

    public func removeAllUsers() throws -> Bool {
        var error = bson_error_t()
        let successful = mongoc_database_remove_all_users(databaseRaw, &error)

        try error.throwIfError()

        return successful
    }

    public func addUser(username username: String, password: String, roles: [String], customData: DocumentData) throws -> Bool {

        var error = bson_error_t()

        var rolesRaw = try MongoBSON(json: roles.toJSON().toString()).bson
        var customDataRaw = try MongoBSON(data: customData).bson

        let successful = mongoc_database_add_user(databaseRaw, username, password, &rolesRaw, &customDataRaw, &error)

        try error.throwIfError()

        return successful
    }

    public func command(command: DocumentData, flags: QueryFlags = .None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0, fields: [String] = []) throws -> MongoCursor {

        var commandRaw = try MongoBSON(data: command).bson
        var fieldsRaw = try MongoBSON(json: fields.toJSON().toString()).bson

        let cursorRaw = mongoc_database_command(databaseRaw, flags.rawFlag, skip.UInt32Value, limit.UInt32Value, batchSize.UInt32Value, &commandRaw, &fieldsRaw, nil)

        let cursor = MongoCursor(cursor: cursorRaw)

        return cursor
    }

    public func drop() throws -> Bool {

        var error = bson_error_t()

        let successful = mongoc_database_drop(databaseRaw, &error)

        try error.throwIfError()

        return successful
    }

    public func hasCollection(name: String) throws -> Bool {

        var error = bson_error_t()

        let successful = mongoc_database_has_collection(databaseRaw, name, &error)

        try error.throwIfError()

        return successful
    }

    public func createCollection(name: String, options: DocumentData) throws -> MongoCollection {

        var error = bson_error_t()

        var optionsRaw = try MongoBSON(data: options).bson

        let collectionRaw = mongoc_database_create_collection(databaseRaw, name, &optionsRaw, &error)

        try error.throwIfError()

        let collection = MongoCollection(name: name, databaseName: self.name, ptr: collectionRaw)

        return collection
    }

//    public func getReadPrefs() throws /* -> _mongoc_read_prefs */ {
////        _mongoc_read_prefs
//    }
//
//    public func setReadPrefs(/*readPrefs: _mongoc_read_prefs*/) throws {
//
//    }
//
//    public func getWriteConcern() throws /* _mongoc_write_concern */ {
//
//    }
//
//    public func setWriteConcern(/*writeConcern: _mongoc_write_concern*/) throws {
//
//    }

    public func findCollections(filter filter: DocumentData) throws -> MongoCursor {

        var error = bson_error_t()
        var filterRaw = try MongoBSON(data: filter).bson

        let cursorRaw = mongoc_database_find_collections(databaseRaw, &filterRaw, &error)

        try error.throwIfError()

        let cursor = MongoCursor(cursor: cursorRaw)

        return cursor
    }

    public func getCollection(name: String) -> MongoCollection {


        let collectionRaw = mongoc_database_get_collection(databaseRaw, name)

        let collection = MongoCollection(name: name, databaseName: self.name, ptr: collectionRaw)

        return collection
    }

    public func getCollectionNames() throws -> [String] {

        var error = bson_error_t()

        let namesRaw = mongoc_database_get_collection_names(databaseRaw, &error)

        try error.throwIfError()

        let names = namesRaw.sequence()!
            .map { String(UTF8String: $0) }
            .flatMap { $0 }

        return names
    }

    public func performBasicDatabaseCommand(command: DocumentData) throws -> DocumentData {

        var command = try MongoBSON(data: command).bson

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_database_command_simple(self.databaseRaw, &command, nil, &reply, &error)

        try error.throwIfError()

        return try MongoBSON(bson: reply).data
    }


    deinit {
        mongoc_database_destroy(databaseRaw)
    }
}
