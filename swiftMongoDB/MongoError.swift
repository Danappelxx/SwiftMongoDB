//
//  MongoError.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

enum CommonError: String {
    case ConnectionNotEstablished = "A connection to MongoDB was not established."
    case CollectionNotRegistered = "The collection was never registered."
    
    case DidNotFind = "No matching documents were found."
    
    case UnknownErrorOccured = "An unknown error occurred."
}

enum CommonCodes: Int {
    case BadRequest = 400
    case NotFound = 404
    case GatewayNotFound = 502
}

class MongoError {

    let error: NSError
    private static let domain = "SwiftMongoDB"

    init(code: Int, userInfo: [NSObject:AnyObject]?) {
        self.error = NSError(domain: "SwiftMongoDB", code: code, userInfo: userInfo)
    }

    convenience init() {
        self.init(code: CommonCodes.BadRequest.rawValue, userInfo: nil)
    }
    
    convenience init(code: Int) {
        self.init(code: code, userInfo: nil)
    }

    convenience init(info: [NSObject:AnyObject]) {
        self.init(code: CommonCodes.BadRequest.rawValue, userInfo: info)
    }

    convenience init(code: Int, message: String) {
        self.init(code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    static func error(code code: CommonCodes, description: CommonError) -> NSError {
        return NSError(domain: self.domain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: description.rawValue])

    }
    
    static func errorFromCommonError(errorType: CommonError) -> NSError {

        switch errorType {
        case .ConnectionNotEstablished:
            return self.error(code: .GatewayNotFound, description: errorType)
            
        case .CollectionNotRegistered:
            return self.error(code: .GatewayNotFound, description: errorType)

        case .DidNotFind:
            return self.error(code: .NotFound, description: errorType)
            
        default:
            return self.error(code: .BadRequest, description: CommonError.UnknownErrorOccured)
        }
    }
//    convenience init(error: commonError) {
//        
//        switch error {
//        case .CollectionNotRegisteredOrConnected:
//            self.init(code: commonCodes.GatewayNotFound, userInfo: )
//        }
//    }
}