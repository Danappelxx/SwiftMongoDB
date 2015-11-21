//
//  MongoCursor.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation
import mongoc

public class MongoCursor {

    let cursor: _mongoc_cursor
    
    // this is way too ugly
    init(collection: MongoCollection, operation: MongoCursorOperation, query: _bson_ptr_mutable, options: (queryFlags: mongoc_query_flags_t, skip: Int, limit: Int, batchSize: Int)) {
        
        switch operation {

        case .Find:
            self.cursor = mongoc_collection_find(collection.collectionRAW, options.queryFlags, options.skip.UInt32Value, options.limit.UInt32Value, options.batchSize.UInt32Value, query, nil, nil)
        }
    }

    private var bson = bson_t()

    var nextDocument: MongoDocument? {
        guard let data = nextData else { return nil }
        return try? MongoDocument(data: data)
    }

    var nextJson: String? {
        return try? MongoBSON.bsonToJson(bson)
    }
    
    var nextData: DocumentData? {
        return try? MongoBSON(bson: bson).data
    }

    /// Advances the cursor to the next document and returns whether it was successful.
    var nextIsOK: Bool {

        var bsonPtr = withUnsafePointer(&bson) { $0 }

        let isOk = mongoc_cursor_next(cursor, &bsonPtr)

        if isOk {
            self.bson = bsonPtr.memory
        }

        bsonPtr = nil

        return isOk
    }

    var lastError: MongoError {
        var error = bson_error_t()
        mongoc_cursor_error(self.cursor, &error)
        return error.error
    }

    deinit {
        mongoc_cursor_destroy(self.cursor)
    }
}

enum MongoCursorOperation {
    case Find
}
