//
//  MongoError.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

enum commonError: String {
    case ConnectionNotEstablished = "A connection to MongoDB was not established."
    case CollectionNotRegistered = "The collection was never registered."
    
    case UnknownErrorOccured = "An unknown error occurred."
}

enum commonCodes: Int {
    case BadRequest = 400
    case GatewayNotFound = 502
}

class MongoError {

    let error: NSError
    private static let domain = "SwiftMongoDB"

    init(code: Int, userInfo: [NSObject:AnyObject]?) {
        self.error = NSError(domain: "SwiftMongoDB", code: code, userInfo: userInfo)
    }

    convenience init() {
        self.init(code: commonCodes.BadRequest.rawValue, userInfo: nil)
    }
    
    convenience init(code: Int) {
        self.init(code: code, userInfo: nil)
    }

    convenience init(info: [NSObject:AnyObject]) {
        self.init(code: commonCodes.BadRequest.rawValue, userInfo: info)
    }

    convenience init(code: Int, message: String) {
        self.init(code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    static func errorFromCommonError(errorType: commonError) -> NSError {

        switch errorType {
        case .ConnectionNotEstablished:
            return NSError(domain: self.domain, code: commonCodes.GatewayNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey: errorType.rawValue])

        case .CollectionNotRegistered:
            return NSError(domain: self.domain, code: commonCodes.GatewayNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey: errorType.rawValue])

        default:
            return NSError(domain: self.domain, code: commonCodes.BadRequest.rawValue, userInfo: [NSLocalizedDescriptionKey: commonError.UnknownErrorOccured.rawValue])
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