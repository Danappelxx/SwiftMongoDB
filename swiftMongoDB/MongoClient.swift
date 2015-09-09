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
    public var databaseName: String? {
        return self.databaseNameInternal
    }
    private var databaseNameInternal = String()

    
    public let port: Int
    public let host: String

    let clientRAW: _mongoc_client



    public init(host: String, port: Int, database: String? = nil) throws {

        self.clientURI = "mongodb://\(host):\(port)"        

        self.host = host
        self.port = port

        self.clientRAW = mongoc_client_new(self.clientURI)

        if database == nil {
            self.databaseNameInternal = self.getDefaultDatabaseName()
        } else {
            self.databaseNameInternal = database!
        }

        mongoc_init()

        let reply = bson_new()
        var status = bson_error_t()
        mongoc_client_get_server_status(self.clientRAW, nil, reply, &status)


        if status.code.mongoError != MongoError.NoError {
            print(errorMessageToString(&status.message))
            throw status.code.mongoError
        }
    }
    
    public func setDatabaseName(name: String) {
        self.databaseNameInternal = name
    }
    
    deinit {
        mongoc_client_destroy(self.clientRAW)
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
        let database = mongoc_client_get_default_database(self.clientRAW)

        let databaseNameRAW = mongoc_database_get_name(database)
        let databaseName = NSString(UTF8String: databaseNameRAW)

        return databaseName! as String
    }

//    public func getDatabases() -> Void {
//        
//        var error = bson_error_t()
//        let databases = mongoc_client_find_databases(self.clientRAW, &error)
//    }
}



