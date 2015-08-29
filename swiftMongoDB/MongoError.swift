//
//  MongoError.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

enum MongoError: ErrorType {

    case ConnectionNotEstablished
    case CollectionNotRegistered
    case NoDocumentsMatched

}