////
////  MongoCursor.swift
////  swiftMongoDB
////
////  Created by Dan Appel on 8/20/15.
////  Copyright © 2015 Dan Appel. All rights reserved.
////

import Foundation

public class MongoCursor {

    let cursorRAW: _mongoc_cursor
    let collection: MongoCollection
    
    // this is way too ugly
    init(collection: MongoCollection, operation: MongoCursorOperation, query: _bson_ptr_mutable, options: (queryFlags: mongoc_query_flags_t, skip: Int, limit: Int, batchSize: Int)) {

        self.collection = collection
        
        switch operation {

        case .Find:
            self.cursorRAW = mongoc_collection_find(collection.collectionRAW, options.queryFlags, options.skip.UInt32Value, options.limit.UInt32Value, options.batchSize.UInt32Value, query, nil, nil)
            break
        }
        
        var outputDocumentBSONTemp = bson_t()
        self.outputDocumentBSON = bsonToPointer(&outputDocumentBSONTemp)
    }

    private func bsonToPointer(inout BSON: bson_t) -> _bson_ptr_immutable {
        
        return withUnsafePointer(&BSON, { (BSONPTR) -> _bson_ptr_immutable in
            return BSONPTR
        })
    }
    
    
    private var outputDocumentBSON: _bson_ptr_immutable = nil

    var nextDocument: MongoDocument? {

        if let documentData = self.nextDocumentData {
            return try! MongoDocument(data: documentData)
        }

        return nil
    }
    
    var nextDocumentJSON: String {
        let rawJSON = bson_as_json(self.outputDocumentBSON, nil)
        let NSJSON = NSString(UTF8String: rawJSON)
        return String(NSJSON)
    }
    
    var nextDocumentBSON: _bson_ptr_immutable {
        return self.outputDocumentBSON
    }
    
    var nextDocumentData: DocumentData? {
        
        do {
            return try MongoBSONDecoder(BSON: self.nextDocumentBSON).result.data
        } catch {
            return nil
        }
    }
    
    var nextIsOK: Bool {
        return mongoc_cursor_next(self.cursorRAW, &self.outputDocumentBSON)
    }

    var lastError: bson_error_t {
        var error = bson_error_t()
        mongoc_cursor_error(self.cursorRAW, &error)
        return error
    }

    deinit {
        self.outputDocumentBSON = nil
        mongoc_cursor_destroy(self.cursorRAW)
    }
}

enum MongoCursorOperation {
    case Find
}

struct MongoOperationOptions {

    var operation: MongoCursorOperation?
    var queryFlags: mongoc_query_flags_t = MONGOC_QUERY_NONE
    var skip: Int?
    private var skipUInt32: UInt32 {
        return UInt32(skip!)
    }
    var limit: Int?
    private var limitUInt32: UInt32 {
        return UInt32(limit!)
    }
    var batchSize: Int?
    private var batchSizeUInt32: UInt32 {
        return UInt32(batchSize!)
    }

    var query: _bson_ptr_mutable?
//    var fields: _bson_ptr_immutable?
//    var readPrefs: _mongoc_read_prefs?
}