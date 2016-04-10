//
//  MongoError.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import CMongoC

public struct MongoError: ErrorProtocol, CustomStringConvertible {

    public let description: String
    public let code: Int
    public let domain: Int // default is 10101 for SwiftMongoDB

    public var isError: Bool {
        return self.code != 0
    }


    public init(description: String, code: Int, domain: Int = 10101) {
        #if os(Linux)
        self.description = ""
        print(description)
        #else
        self.description = description
        #endif
        self.code = code
        self.domain = domain
    }

    init(error: bson_error_t) {

        var messageRAW = error.message
        var message = mongocErrorMessageToString(&messageRAW)
        #if os(Linux)
        print(message)
        message = ""
        #endif

        let code = Int(error.code)
        let domain = Int(error.domain)

        self.init(description: message, code: code, domain: domain)
    }

    // TODO: - Turn this into an enum
    // Error code model:
    // 1000-1099 General
    // 1100-1199 BSON
    // TBD

    // General
    public static let UnknownError = MongoError(description: "An unknown error occurred.", code: 1001)
    public static let InvalidJSON = MongoError(description: "The given JSON string is invalid.", code: 1003)
    public static let InvalidData = MongoError(description: "Converting the given data to JSON failed.", code: 1004)

    // BSON
    public static let CorruptDocument = MongoError(description: "The given document is corrupt.", code: 1101)


}

public extension bson_error_t {
    var error: MongoError {
        return MongoError(error: self)
    }

    func throwIfError() throws {
        if self.error.isError {
            throw self.error
        }
    }
}

func mongocErrorMessageToString(error: inout _mongoc_error_message) -> String {
    return withUnsafePointer(&error) {
        String(cString:UnsafePointer($0))
    }
}




// List of errors for future reference:

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
