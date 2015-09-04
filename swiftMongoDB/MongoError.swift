//
//  MongoError.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

internal enum MongoError: ErrorType {

    case ConnectionNotEstablished
    case NoDocumentsMatched
    
    case ConnectionToHostFailed
    
    case CorruptDocument

    case UnknownErrorOccurred
    
    case TypeNotSupported
    
    
    case NoError

}

internal func codeToMongoError(code: UInt32) -> MongoError {
    
    switch code {
    case 0: return MongoError.NoError
    
    case 5: return MongoError.ConnectionToHostFailed
        
    case 18: return MongoError.CorruptDocument

    default:
        return MongoError.UnknownErrorOccurred
    }
}

internal func errorMessageToString(inout error: _mongoc_error_message) -> String {
    return withUnsafePointer(&error) {
        String.fromCString(UnsafePointer($0))!
    }
}