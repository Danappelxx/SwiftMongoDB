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


        if codeToMongoError(status.code) != MongoError.NoError {
            print(errorMessageToString(&status.message))
            throw codeToMongoError(status.code)
        }


//        let insertedDocument = bson_new()
//        let query = insertedDocument
//        let jsonStr = "{ \"hello\" : \"world!!\" } "
//
//        var bsonError = bson_error_t()
//
//        bson_init_from_json(insertedDocument, jsonStr, jsonStr.characters.count, &bsonError)
//
//        let collection = mongoc_client_get_collection(client, databaseName, collectionName)
//
//        mongoc_collection_insert(collection, MONGOC_INSERT_NONE, insertedDocument, nil, &bsonError)
//
//        let cursor = mongoc_collection_find(collection, MONGOC_QUERY_NONE, 0, 0, 0, query, nil, nil)
//
//        var documentRAW = bson_t()
//
//        // turns unsafemutablepointer into unsafepointer
//        var document = withUnsafePointer(&documentRAW) { (bsonPTR) -> UnsafePointer<bson_t> in
//            return bsonPTR
//        }
//
//        while mongoc_cursor_next(cursor, &document) {
//            let str = bson_as_json(document, nil)
//
//            print(str)
//
//            bson_free(str)
//        }
//
//        if mongoc_cursor_error(cursor, &bsonError) {
//            print(bsonError.message)
//        }
//
//        query.dealloc(1)
////        bson_destroy(query)
//        mongoc_cursor_destroy(cursor)
//        mongoc_collection_destroy(collection)
//        mongoc_client_destroy(client)
//
//        mongoc_cleanup()
    }
}