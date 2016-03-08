//
//  Client.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import CMongoC
@_exported import BinaryJSON

public final class Client {

    public let uri: String

    let pointer: _mongoc_client

    public init(uri: String) throws {
        self.uri = uri

        mongoc_init()

        self.pointer = mongoc_client_new(uri)

        try checkConnection()
    }

    public convenience init(host: String, port: Int) throws {
        try self.init(uri: "mongodb://\(host):\(port)")
    }

    /**
     Attempts to run the `ping` command on the database. If it executes without throwing errors, you are successfully connected.

     - throws: Any errors it encounters while connecting to the database.
     */
    public func checkConnection() throws {
        try basicCommand(["ping": 1], databaseName: "local")
    }

    deinit {
        mongoc_client_destroy(self.pointer)
        mongoc_cleanup()
    }


    public func getDatabaseNames() throws -> [String] {
        var error = bson_error_t()
        var buffer = mongoc_client_get_database_names(self.pointer, &error)

        try error.throwIfError()

        var names = [String]()

        while buffer.memory != nil {

            let name = String.fromCString(buffer.memory)!
            names.append(name)

            buffer = buffer.successor()
        }

        return names
    }

    public func basicCommand(command: BSON.Document, databaseName: String) throws -> BSON.Document {

        guard let commandBSON = BSON.unsafePointerFromDocument(command) else {
            throw MongoError.InvalidData
        }
        var reply = bson_t()
        var error = bson_error_t()

        mongoc_client_command_simple(self.pointer, databaseName, commandBSON, nil, &reply, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }

        return res
    }

    // Waiting on BinaryJSON to support [String] bson
//    public func performClientCommand(query: BSON.Document, database: Database, fields: [String], flags: QueryFlags, options: QueryOptions) throws -> Cursor {
//
//        let fields = BSON.Value.Array(fields.map { BSON.Value.String($0) })
//
//        // this isnt possible yet
//        guard let fieldsBSON = BSON.unsafePointerFromDocument(fields) else {
//            throw MongoError.InvalidData
//        }
//
//        var query = try MongoBSON(data: query).bson
//        var fields = try MongoBSON(json: fieldsJSON ).bson
//
//        let cursor = mongoc_client_command(pointer, database.name, flags.rawFlag, options.skip.UInt32Value, options.limit.UInt32Value, options.batchSize.UInt32Value, &query, &fields, nil)
//
//        return Cursor(cursor: cursor)
//    }

    public func getDatabasesCursor() throws -> Cursor {

        var error = bson_error_t()

        let cursor = mongoc_client_find_databases(pointer, &error)

        try error.throwIfError()

        return Cursor(pointer: cursor)
    }

    public func getServerStatus() throws -> BSON.Document {

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_client_get_server_status(pointer, nil, &reply, &error)

        try error.throwIfError()

        guard let status = BSON.documentFromUnsafePointer(&reply) else {
            throw MongoError.CorruptDocument
        }

        return status
    }
}
