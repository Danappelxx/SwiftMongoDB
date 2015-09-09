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