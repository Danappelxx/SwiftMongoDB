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

    private func cursor(operation operation: MongoCursorOperation, query: _bson_ptr_mutable, options: (queryFlags: mongoc_query_flags_t, skip: Int, limit: Int, batchSize: Int)) -> MongoCursor {

        // ugh so ugly
        return MongoCursor(collection: self, operation: operation, query: query, options: (queryFlags: options.queryFlags, skip: options.skip, limit: options.limit, batchSize: options.batchSize))
    }

    public enum InsertFlags {
        case None
        case ContinueOnError
    }

    public func insert(document: MongoDocument, flags: InsertFlags = InsertFlags.None) throws {

        let insertFlags: mongoc_insert_flags_t
        switch flags {
        case .None: insertFlags = MONGOC_INSERT_NONE
        case .ContinueOnError: insertFlags = MONGOC_INSERT_CONTINUE_ON_ERROR
        }

        var bsonError = bson_error_t()

        mongoc_collection_insert(self.collectionRAW, insertFlags, document.BSONRAW, nil, &bsonError)

        if bsonError.code.mongoError != MongoError.NoError {

            print(errorMessageToString(&bsonError.message))
            throw bsonError.code.mongoError
        }
    }
    
    public func insert(document: DocumentData, flags: InsertFlags = InsertFlags.None) throws {

        do {
            try self.insert(MongoDocument(data: document), flags: flags)
        } catch {
            throw error
        }
    }

    public enum QueryFlags {
        case None
        case TailableCursor
        case SlaveOK
        case OPLogReplay
        case NoCursorTimout
        case AwaitData
        case Exhaust
        case Partial
    }

    public func find(query: DocumentData = DocumentData(), flags: QueryFlags = QueryFlags.None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0) throws -> [MongoDocument] {

        var queryBSON = bson_t()
        try! MongoBSONEncoder(data: query).copyTo(&queryBSON)

        let queryFlags: mongoc_query_flags_t
        switch flags {
        case .None: queryFlags = MONGOC_QUERY_NONE; break
        case .TailableCursor: queryFlags = MONGOC_QUERY_TAILABLE_CURSOR; break
        case .SlaveOK: queryFlags = MONGOC_QUERY_SLAVE_OK; break
        case .OPLogReplay: queryFlags = MONGOC_QUERY_OPLOG_REPLAY; break
        case .NoCursorTimout: queryFlags = MONGOC_QUERY_NO_CURSOR_TIMEOUT; break
        case .AwaitData: queryFlags = MONGOC_QUERY_AWAIT_DATA; break
        case .Exhaust: queryFlags = MONGOC_QUERY_EXHAUST; break
        case .Partial: queryFlags = MONGOC_QUERY_PARTIAL; break
        }

        // standard options - should be customizable later on
        let cursor = self.cursor(operation: .Find, query: &queryBSON, options: (queryFlags: queryFlags, skip: skip, limit: skip, batchSize: skip))

        var outputDocuments = [MongoDocument]()

        while cursor.nextIsOK {
            print(cursor.nextDocumentJSON)
            
            guard let nextDocument = cursor.nextDocument else {
                throw MongoError.CorruptDocument
            }
            outputDocuments.append(nextDocument)
        }

        if cursor.lastError.code.mongoError != MongoError.NoError {
            var errorMessage = cursor.lastError.message
            print(errorMessageToString(&errorMessage))

            throw cursor.lastError.code.mongoError
        }

        return outputDocuments
    }
    
    public func findOne(query: DocumentData = DocumentData(), flags: QueryFlags = QueryFlags.None, skip: Int = 0, limit: Int = 0, batchSize: Int = 0) throws -> MongoDocument? {
        
        let queryBSON = try! MongoBSONEncoder(data: query).BSONRAW
        
        let queryFlags: mongoc_query_flags_t
        switch flags {
        case .None: queryFlags = MONGOC_QUERY_NONE; break
        case .TailableCursor: queryFlags = MONGOC_QUERY_TAILABLE_CURSOR; break
        case .SlaveOK: queryFlags = MONGOC_QUERY_SLAVE_OK; break
        case .OPLogReplay: queryFlags = MONGOC_QUERY_OPLOG_REPLAY; break
        case .NoCursorTimout: queryFlags = MONGOC_QUERY_NO_CURSOR_TIMEOUT; break
        case .AwaitData: queryFlags = MONGOC_QUERY_AWAIT_DATA; break
        case .Exhaust: queryFlags = MONGOC_QUERY_EXHAUST; break
        case .Partial: queryFlags = MONGOC_QUERY_PARTIAL; break
        }
        
        // standard options - should be customizable later on
        let cursor = self.cursor(operation: .Find, query: queryBSON, options: (queryFlags: queryFlags, skip: skip, limit: skip, batchSize: skip))
        
        if cursor.nextIsOK {
            
            guard let nextDocument = cursor.nextDocument else {
                throw MongoError.CorruptDocument
            }
            
            return nextDocument
        }
        
        return nil
    }

    public enum UpdateFlags {
        case None
        case Upsert
        case MultiUpdate
    }

    public func update(query: DocumentData = DocumentData(), newValue: DocumentData, flags: UpdateFlags = UpdateFlags.None) throws -> Bool {

        let updateFlags: mongoc_update_flags_t
        switch flags {
        case .None: updateFlags = MONGOC_UPDATE_NONE; break
        case .Upsert: updateFlags = MONGOC_UPDATE_UPSERT; break
        case .MultiUpdate: updateFlags = MONGOC_UPDATE_MULTI_UPDATE; break
        }

        var queryBSON = bson_t()
        try! MongoBSONEncoder(data: query).copyTo(&queryBSON)

        var documentBSON = bson_t()
        try! MongoBSONEncoder(data: newValue).copyTo(&documentBSON)

        var error = bson_error_t()
        let success = mongoc_collection_update(self.collectionRAW, updateFlags, &queryBSON, &documentBSON, nil, &error)

        if error.code.mongoError != MongoError.NoError {
            
            print(errorMessageToString(&error.message))

            throw error.code.mongoError
        }

        return success
    }

    public enum RemoveFlags {
        case None
        case SingleRemove
    }

    public func remove(query: DocumentData = DocumentData(), flags: RemoveFlags = RemoveFlags.None) throws -> Bool {

        let removeFlags: mongoc_remove_flags_t
        switch flags {
        case .None: removeFlags = MONGOC_REMOVE_NONE; break
        case .SingleRemove: removeFlags = MONGOC_REMOVE_SINGLE_REMOVE; break
        }

        var queryBSON = bson_t()
        try! MongoBSONEncoder(data: query).copyTo(&queryBSON)

        var error = bson_error_t()
        let success = mongoc_collection_remove(self.collectionRAW, removeFlags, &queryBSON, nil, &error)

        if error.code.mongoError != MongoError.NoError {
            throw error.code.mongoError
        }

        return success
    }
}