////
////  MongoCollection.swift
////  swiftMongoDB
////
////  Created by Dan Appel on 8/20/15.
////  Copyright © 2015 Dan Appel. All rights reserved.
////

public class MongoCollection {

    public let client: MongoClient
    public let collectionName: String

    let clientRAW: _mongoc_client
    let collectionRAW: _mongoc_collection

    public init(collectionName: String, client: MongoClient) {

        self.client = client
        self.clientRAW = client.clientRAW

        self.collectionName = collectionName

        self.collectionRAW = mongoc_client_get_collection(self.clientRAW, self.client.databaseName, self.collectionName)

    }

    deinit {
        mongoc_client_destroy(self.clientRAW)
        mongoc_collection_destroy(self.collectionRAW)
    }

    private func cursor(options: MongoOperationOptions) -> MongoCursor {
        return MongoCursor(collection: self, options: options)
    }

    public enum InsertFlags {
        case None
        case ContinueOnError
    }

    public func insert(document: MongoDocument, flags: InsertFlags = InsertFlags.None, writeConcern: MongoWriteConcern? = nil) throws {

        let insertFlags: mongoc_insert_flags_t
        switch flags {
        case .None: insertFlags = MONGOC_INSERT_NONE
        case .ContinueOnError: insertFlags = MONGOC_INSERT_CONTINUE_ON_ERROR
        }

        var bsonError = bson_error_t()

        mongoc_collection_insert(self.collectionRAW, insertFlags, document.BSONRAW, nil, &bsonError)

        let error = codeToMongoError(bsonError.code)
        if error != MongoError.NoError {

            print(errorMessageToString(&bsonError.message))
            throw error
        }
    }

    public func find(query: DocumentData = DocumentData()) throws -> [MongoDocument] {

        let queryBSON = MongoBSONEncoder(query).BSONRAW

        // standard options - should be customizable later on
        var options = MongoOperationOptions()
        options.operation = MongoCursorOperation.Find
        options.skip = 0
        options.limit = 0
        options.batchSize = 0

        options.query = queryBSON

        let cursor = self.cursor(options)

        var outputDocuments = [MongoDocument]()

        while cursor.nextIsOK {
            print(cursor.nextDocumentJSON)
            outputDocuments.append(cursor.nextDocument)
        }

        if codeToMongoError(cursor.lastError.code) != MongoError.NoError {
            var errorMessage = cursor.lastError.message
            print(errorMessageToString(&errorMessage))

            throw codeToMongoError(cursor.lastError.code)
        }

        return outputDocuments
    }
}