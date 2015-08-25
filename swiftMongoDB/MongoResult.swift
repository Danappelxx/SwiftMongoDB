//
//  MongoResult.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

public enum MongoResult<T> {
    case Success(T)
    case Failure(NSError)
    
    public var isSuccessful: Bool {
        switch self {
        case .Success(_):
            return true
        case .Failure(_):
            return false
        }
    }
    
    public var successValue: T? {
        switch self {
        case .Success(let result):
            return result
        default:
            return nil
        }
    }
    
    public var errorValue: NSError? {
        switch self {
        case .Failure(let error):
            return error
        default:
            return nil
        }
    }
}

/* use like this:

var result = functionThatReturnsMongoResult()

switch result {
case .Success(let result):
    doSomethingWithResult(result)
case .Failure(let err):
    print(err)
}

*/