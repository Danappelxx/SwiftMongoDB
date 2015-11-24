//
//  MongoCursor.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import mongoc

public class MongoCursor {

    typealias MongoCursorOptions = (queryFlags: mongoc_query_flags_t, skip: Int, limit: Int, batchSize: Int)

    enum MongoCursorOperation {
        case Find
    }

    let cursor: _mongoc_cursor
    
    init(cursor: _mongoc_cursor) {
        self.cursor = cursor
    }
    
    // this is way too ugly
    init(collection: MongoCollection, operation: MongoCursorOperation, query: _bson_ptr_mutable, options: MongoCursorOptions) {
        
        switch operation {

        case .Find:
            cursor = mongoc_collection_find(
                collection.collectionRaw,
                options.queryFlags,
                options.skip.UInt32Value,
                options.limit.UInt32Value,
                options.batchSize.UInt32Value,
                query, nil, nil
            )
        }
    }

    deinit {
        mongoc_cursor_destroy(self.cursor)
    }


    private var nextBson = bson_t()

    var nextDocument: MongoDocument? {
        guard let data = nextData else { return nil }
        return try? MongoDocument(data: data)
    }

    var nextJson: String? {
        return try? MongoBSON.bsonToJson(nextBson)
    }
    
    var nextData: DocumentData? {
        return try? MongoBSON(bson: nextBson).data
    }

    /// Advances the cursor to the next document and returns whether it was successful.
    var nextIsOK: Bool {

        var bsonPtr: UnsafePointer<bson_t> = nil

        let isOk = mongoc_cursor_next(cursor, &bsonPtr)

        if isOk {
            self.nextBson = bsonPtr.memory
        }

        return isOk
    }

    var lastError: MongoError {
        var error = bson_error_t()
        mongoc_cursor_error(self.cursor, &error)
        return error.error
    }
    
    func getDocumentsJson() throws -> [String] {

        var documents = [String]()
        while nextIsOK {

            guard let nextJson = nextJson else {
                throw MongoError.CorruptDocument
            }

            documents.append(nextJson)
        }
        
        return documents
    }
    
    func getDocumentsData() throws -> [DocumentData] {

        let documentsOptional = try getDocumentsJson()
            .map { try $0.parseJSONDocumentData() }

        let documents = try documentsOptional
            .map { doc -> DocumentData in
                guard let doc = doc else {
                    throw MongoError.CorruptDocument
                }
                return doc
            }

        return documents
    }
    
    func getDocuments() throws -> [MongoDocument] {

        let documents = try getDocumentsData()
            .map { try MongoDocument(data: $0) }

        return documents
    }
}
