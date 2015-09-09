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
    public let databaseName: String
    public let port: Int
    public let host: String

    let clientRAW: _mongoc_client



    public init(host: String, port: Int, database databaseName: String) throws {

        self.clientURI = "mongodb://\(host):\(port)"
        self.databaseName = databaseName
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
    }
    
    deinit {
        mongoc_client_destroy(self.clientRAW)
    }
}