//
//  MongoError.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

public enum MongoError: ErrorType {

    // BSON
    
    case TypeNotSupported
    case CorruptDocument

    // Client
    case NoServersFound
    case ConnectionToHostFailed
    case ConnectionNotEstablished
    case FailedToReadBytes

    /// Collection
    // Query
    case NoDocumentsMatched
    // Insert
    case DuplicateObjectID
    
    // Documents
    case MisplacedOrMissingOID
    
    // General
    case NoError
    case UnknownErrorOccurred
}

internal func codeToMongoError(code: UInt32) -> MongoError {
    
    switch code {

    case 0: return MongoError.NoError
        
    case 4: return MongoError.FailedToReadBytes
    
    case 5: return MongoError.ConnectionToHostFailed
        
    case 18: return MongoError.CorruptDocument
        
    case 11000: return MongoError.DuplicateObjectID
        
    case 13053: return MongoError.NoServersFound

    default:
        return MongoError.UnknownErrorOccurred
    }
}

internal func errorMessageToString(inout error: _mongoc_error_message) -> String {
    return withUnsafePointer(&error) {
        String.fromCString(UnsafePointer($0))!
    }
}

// just to be less verbose - kind of silly to extend an integer, however :)
extension UInt32 {
    internal var mongoError: MongoError {
        return codeToMongoError(self)
    }
}

// should migrate to using these codes instead of raw ints
//public struct mongoc_error_domain_t : RawRepresentable {
//    public init(_ rawValue: UInt32)
//    public init(rawValue: UInt32)
//    public var rawValue: UInt32
//}
//public var MONGOC_ERROR_CLIENT: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_STREAM: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_PROTOCOL: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_CURSOR: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_QUERY: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_INSERT: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_SASL: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_BSON: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_MATCHER: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_NAMESPACE: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_COMMAND: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_COLLECTION: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_GRIDFS: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_SCRAM: mongoc_error_domain_t { get }
//public var MONGOC_ERROR_SERVER_SELECTION: mongoc_error_domain_t { get }
//
//public struct mongoc_error_code_t : RawRepresentable {
//    public init(_ rawValue: UInt32)
//    public init(rawValue: UInt32)
//    public var rawValue: UInt32
//}
//public var MONGOC_ERROR_STREAM_INVALID_TYPE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_STREAM_INVALID_STATE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_STREAM_NAME_RESOLUTION: mongoc_error_code_t { get }
//public var MONGOC_ERROR_STREAM_SOCKET: mongoc_error_code_t { get }
//public var MONGOC_ERROR_STREAM_CONNECT: mongoc_error_code_t { get }
//public var MONGOC_ERROR_STREAM_NOT_ESTABLISHED: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CLIENT_NOT_READY: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CLIENT_TOO_BIG: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CLIENT_TOO_SMALL: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CLIENT_GETNONCE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CLIENT_AUTHENTICATE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CLIENT_NO_ACCEPTABLE_PEER: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CLIENT_IN_EXHAUST: mongoc_error_code_t { get }
//public var MONGOC_ERROR_PROTOCOL_INVALID_REPLY: mongoc_error_code_t { get }
//public var MONGOC_ERROR_PROTOCOL_BAD_WIRE_VERSION: mongoc_error_code_t { get }
//public var MONGOC_ERROR_CURSOR_INVALID_CURSOR: mongoc_error_code_t { get }
//public var MONGOC_ERROR_QUERY_FAILURE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_BSON_INVALID: mongoc_error_code_t { get }
//public var MONGOC_ERROR_MATCHER_INVALID: mongoc_error_code_t { get }
//public var MONGOC_ERROR_NAMESPACE_INVALID: mongoc_error_code_t { get }
//public var MONGOC_ERROR_NAMESPACE_INVALID_FILTER_TYPE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_COMMAND_INVALID_ARG: mongoc_error_code_t { get }
//public var MONGOC_ERROR_COLLECTION_INSERT_FAILED: mongoc_error_code_t { get }
//public var MONGOC_ERROR_COLLECTION_UPDATE_FAILED: mongoc_error_code_t { get }
//public var MONGOC_ERROR_COLLECTION_DELETE_FAILED: mongoc_error_code_t { get }
//public var MONGOC_ERROR_COLLECTION_DOES_NOT_EXIST: mongoc_error_code_t { get }
//public var MONGOC_ERROR_GRIDFS_INVALID_FILENAME: mongoc_error_code_t { get }
//public var MONGOC_ERROR_SCRAM_NOT_DONE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_SCRAM_PROTOCOL_ERROR: mongoc_error_code_t { get }
//public var MONGOC_ERROR_QUERY_COMMAND_NOT_FOUND: mongoc_error_code_t { get }
//public var MONGOC_ERROR_QUERY_NOT_TAILABLE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_SERVER_SELECTION_BAD_WIRE_VERSION: mongoc_error_code_t { get }
//public var MONGOC_ERROR_SERVER_SELECTION_FAILURE: mongoc_error_code_t { get }
//public var MONGOC_ERROR_SERVER_SELECTION_INVALID_ID: mongoc_error_code_t { get }
//
///* Dup with query failure. */
//public var MONGOC_ERROR_PROTOCOL_ERROR: mongoc_error_code_t { get }
