//
//  MongoDB.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import mongoc

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
}


// todo:

//mongoc_cursor_t               *mongoc_client_command              (mongoc_client_t              *client,
//    const char                   *db_name,
//    mongoc_query_flags_t          flags,
//    uint32_t                      skip,
//    uint32_t                      limit,
//    uint32_t                      batch_size,
//    const bson_t                 *query,
//    const bson_t                 *fields,
//    const mongoc_read_prefs_t    *read_prefs);
//mongoc_gridfs_t               *mongoc_client_get_gridfs           (mongoc_client_t              *client,
//    const char                   *db,
//    const char                   *prefix,
//    bson_error_t                 *error);
//mongoc_cursor_t               *mongoc_client_find_databases       (mongoc_client_t              *client,
//    bson_error_t                 *error);
//bool                           mongoc_client_get_server_status    (mongoc_client_t              *client,
//    mongoc_read_prefs_t          *read_prefs,
//    bson_t                       *reply,
//    bson_error_t                 *error);
//int32_t                        mongoc_client_get_max_message_size (mongoc_client_t              *client) BSON_GNUC_DEPRECATED;
//int32_t                        mongoc_client_get_max_bson_size    (mongoc_client_t              *client) BSON_GNUC_DEPRECATED;
//const mongoc_write_concern_t  *mongoc_client_get_write_concern    (const mongoc_client_t        *client);
//void                           mongoc_client_set_write_concern    (mongoc_client_t              *client,
//    const mongoc_write_concern_t *write_concern);
//const mongoc_read_prefs_t     *mongoc_client_get_read_prefs       (const mongoc_client_t        *client);
//void                           mongoc_client_set_read_prefs       (mongoc_client_t              *client,
//    const mongoc_read_prefs_t    *read_prefs);
//#ifdef MONGOC_ENABLE_SSL
//void                           mongoc_client_set_ssl_opts         (mongoc_client_t              *client,
//const mongoc_ssl_opt_t       *opts);
//#endif
