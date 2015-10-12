////
////  MongoDB.swift
////  swiftMongoDB
////
////  Created by Dan Appel on 8/20/15.
////  Copyright © 2015 Dan Appel. All rights reserved.
////

import Foundation

public class MongoClient {

    public let clientURI: String
    public var databaseName: String {
        return self.databaseNameInternal
    }
    private var databaseNameInternal = String()
    
    private var databaseRAW: _mongoc_database {
        return mongoc_client_get_database(self.clientRAW, self.databaseName)
    }


    public let port: Int
    public let host: String

    let clientRAW: _mongoc_client



    public init(host: String, port: Int, database: String? = nil) throws {

        self.clientURI = "mongodb://\(host):\(port)"

        self.host = host
        self.port = port

        self.clientRAW = mongoc_client_new(self.clientURI)

        mongoc_init()

        let reply = bson_new()
        var status = bson_error_t()
        mongoc_client_get_server_status(self.clientRAW, nil, reply, &status)


        if status.code.mongoError != MongoError.NoError {
            print(errorMessageToString(&status.message))
            throw status.code.mongoError
        }
        
        if database == nil {
            self.databaseNameInternal = self.getDefaultDatabaseName()
        } else {
            self.databaseNameInternal = database!
        }
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
        
        self.clientRAW = mongoc_client_new(self.clientURI)
        
        mongoc_init()
        
        let reply = bson_new()
        var status = bson_error_t()
        mongoc_client_get_server_status(self.clientRAW, nil, reply, &status)
        
        
        if status.code.mongoError != MongoError.NoError {
        print(errorMessageToString(&status.message))
        throw status.code.mongoError
        }
        
        self.databaseNameInternal = database
        
    }

    
    public func setDatabaseName(name: String) {
        self.databaseNameInternal = name
    }
    
    deinit {
        mongoc_client_destroy(self.clientRAW)
        mongoc_cleanup()
    }


    public func getDatabaseNames() -> [String] {
        var error = bson_error_t()
        let namesRAW = mongoc_client_get_database_names(self.clientRAW, &error)

        var names = [String]()

        for (var i = 0; namesRAW.advancedBy(i).memory != nil; i++) {
            let nameRawCur = namesRAW.advancedBy(i)

            let currName = NSString(UTF8String: nameRawCur.memory)!

            names.append(currName as String)
        }

        return names
    }
    
    public func getCollectionNamesInDatabase(database: String) -> [String] {
        
        let database = mongoc_client_get_database(self.clientRAW, database)
        
        var error = bson_error_t()
        let namesRAW = mongoc_database_get_collection_names(database, &error)
        
        var names = [String]()
        
        for (var i = 0; namesRAW.advancedBy(i).memory != nil; i++) {
            let nameRawCur = namesRAW.advancedBy(i)
            
            let currName = NSString(UTF8String: nameRawCur.memory)!
            
            names.append(currName as String)
        }
        
        return names
        
    }
    
    public func getDefaultDatabaseName() -> String {
        let databaseNameRAW = mongoc_database_get_name(self.clientRAW)
        let databaseName = NSString(UTF8String: databaseNameRAW)

        return databaseName! as String
    }
    
    
    
    public func performBasicClientCommand(command: DocumentData) throws -> DocumentData {

        var commandRAW = bson_t()
        try MongoBSONEncoder(data: command).copyTo(&commandRAW)

        var reply = bson_t()
        var error = bson_error_t()
        
        mongoc_client_command_simple(self.clientRAW, self.databaseNameInternal, &commandRAW, nil, &reply, &error)

        if error.code.mongoError != MongoError.NoError {
            print(errorMessageToString(&error.message))
            throw error.code.mongoError
        }

        return try MongoBSONDecoder(BSON: &reply).result.data
        //        mongoc_client_command_simple(client: COpaquePointer, db_name: UnsafePointer<Int8>, command: UnsafePointer<bson_t>, read_prefs: COpaquePointer, reply: UnsafeMutablePointer<bson_t>, error: UnsafeMutablePointer<bson_error_t>)
    }

    public func performBasicDatabaseCommand(command: DocumentData) throws -> DocumentData {
        
        var commandRAW = bson_t()
        try MongoBSONEncoder(data: command).copyTo(&commandRAW)
        
        var reply = bson_t()
        var error = bson_error_t()
        
        mongoc_database_command_simple(self.databaseRAW, &commandRAW, nil, &reply, &error)

        if error.code.mongoError != MongoError.NoError {
            print(errorMessageToString(&error.message))
            throw error.code.mongoError
        }
        
        return try MongoBSONDecoder(BSON: &reply).result.data
        //        mongoc_collection_command_simple(collection: COpaquePointer, command: UnsafePointer<bson_t>, read_prefs: COpaquePointer, reply: UnsafeMutablePointer<bson_t>, error: UnsafeMutablePointer<bson_error_t>)
    }
}