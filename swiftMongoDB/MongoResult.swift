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