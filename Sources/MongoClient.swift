//
//  MongoDB.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import CMongoC

public class MongoClient {

    public let clientURI: String

    public let port: Int
    public let host: String

    let clientRaw: _mongoc_client

    public init(host: String, port: Int) throws {

        self.clientURI = "mongodb://\(host):\(port)"

        self.host = host
        self.port = port

        mongoc_init()

        self.clientRaw = mongoc_client_new(self.clientURI)

        try checkConnection()
    }

    // authenticated connection - required specific database
    public convenience init(host: String, port: Int, database: String, usernameAndPassword: (username: String, password: String)) throws {
        try self.init(
            host: host,
            port: port,
            database: database,
            authenticationDatabase: database,
            usernameAndPassword: usernameAndPassword
        )
    }

    // authenticated connection - required specific database and specific database for authentication
    public init(host: String, port: Int, database: String, authenticationDatabase: String, usernameAndPassword: (username: String, password: String)) throws {

        let userAndPass = "\(usernameAndPassword.username):\(usernameAndPassword.password)@"

        self.clientURI = "mongodb://\(userAndPass)\(host):\(port)/\(database)?authSource=\(authenticationDatabase)"

        self.host = host
        self.port = port

        mongoc_init()

        self.clientRaw = mongoc_client_new(self.clientURI)

        try checkConnection()
    }

    /**
     Attempts to run the `ping` command on the database. If it executes without throwing errors, you are successfully connected.

     - throws: Any errors it encounters while connecting to the database.
     */
    public func checkConnection() throws {
        try performBasicClientCommand(["ping":1], databaseName: "local")
    }

    deinit {
        mongoc_client_destroy(self.clientRaw)
        mongoc_cleanup()
    }


    public func getDatabaseNames() throws -> [String] {
        var error = bson_error_t()
        let namesRaw = mongoc_client_get_database_names(self.clientRaw, &error)

        try error.throwIfError()
        let names = namesRaw.sequence()!
            .map { (cStr: UnsafeMutablePointer<Int8>) -> String? in
                return String(UTF8String: cStr)
            }
            .flatMap { $0 }

        return names
    }

    public func performBasicClientCommand(command: DocumentData, databaseName: String) throws -> DocumentData {

        var command = try MongoBSON(data: command).bson

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_client_command_simple(self.clientRaw, databaseName, &command, nil, &reply, &error)

        try error.throwIfError()

        return try MongoBSON(bson: reply).data
    }

    public func performClientCommand(query: DocumentData, database: MongoDatabase, fields: [String], flags: QueryFlags, options: QueryOptions) throws -> MongoCursor {

        var query = try MongoBSON(data: query).bson
        var fields = try MongoBSON(json: fields.toJSON()).bson

        let cursor = mongoc_client_command(clientRaw, database.name, flags.rawFlag, options.skip.UInt32Value, options.limit.UInt32Value, options.batchSize.UInt32Value, &query, &fields, nil)

        return MongoCursor(cursor: cursor)
    }

    public func getDatabasesCursor() throws -> MongoCursor {

        var error = bson_error_t()

        let cursor = mongoc_client_find_databases(clientRaw, &error)

        try error.throwIfError()

        return MongoCursor(cursor: cursor)
    }

    public func getServerStatus() throws -> DocumentData {

        var reply = bson_t()
        var error = bson_error_t()

        mongoc_client_get_server_status(clientRaw, nil, &reply, &error)

        try error.throwIfError()

        return try MongoBSON(bson: reply).data
    }

    //    public func getReadPrefs() throws /* -> _mongoc_read_prefs */ {
    //
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
}


// todo:
// void mongoc_client_set_ssl_opts  (mongoc_client_t *client, const mongoc_ssl_opt_t *opts);
