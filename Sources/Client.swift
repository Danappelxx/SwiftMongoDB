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


    public var databaseNames: [String]? {
        var error = bson_error_t()
        var buffer = mongoc_client_get_database_names(self.pointer, &error)

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

    public func basicCommand(command: BSON.Document, databaseName: String) throws -> BSON.Document {

        let command = try BSON.AutoReleasingCarrier(document: command)

        let reply = BSON.AutoReleasingCarrier(bson: bson_new())
        var error = bson_error_t()

        mongoc_client_command_simple(self.pointer, databaseName, command.pointer, nil, reply.pointer, &error)

        try error.throwIfError()

        guard let res = BSON.documentFromUnsafePointer(reply.pointer) else {
            throw MongoError.CorruptDocument
        }

        return res
    }

    public func command(command: BSON.Document, fields: BSON.Document? = nil, databaseName: String, flags: QueryFlags, options: QueryOptions) throws -> Cursor {

        let command = try BSON.AutoReleasingCarrier(document: command)

        let fields = try fields.map(BSON.AutoReleasingCarrier.init)

        let cursor = mongoc_client_command(
            pointer,
            databaseName,
            flags.rawFlag,
            options.skip.UInt32Value,
            options.limit.UInt32Value,
            options.batchSize.UInt32Value,
            command.pointer,
            fields?.pointer ?? nil,
            nil
        )

        return Cursor(pointer: cursor)
    }

    public func getDatabasesCursor() throws -> Cursor {

        var error = bson_error_t()

        let cursor = mongoc_client_find_databases(pointer, &error)

        try error.throwIfError()

        return Cursor(pointer: cursor)
    }

    public func getServerStatus() throws -> BSON.Document {

        let reply = BSON.AutoReleasingCarrier(bson: bson_new())
        var error = bson_error_t()

        mongoc_client_get_server_status(pointer, nil, reply.pointer, &error)

        try error.throwIfError()

        guard let status = BSON.documentFromUnsafePointer(reply.pointer) else {
            throw MongoError.CorruptDocument
        }

        return status
    }
}
