//
//  MongoCollectionFlags.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 11/21/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import mongoc

public enum UpdateFlags {
    case None
    case Upsert
    case MultiUpdate
    
    internal var rawFlag: mongoc_update_flags_t {
        switch self {
        case .None: return MONGOC_UPDATE_NONE
        case .Upsert: return MONGOC_UPDATE_UPSERT
        case .MultiUpdate: return MONGOC_UPDATE_MULTI_UPDATE
        }
    }
}

public enum RemoveFlags {
    case None
    case SingleRemove
    
    internal var rawFlag: mongoc_remove_flags_t {
        switch self {
        case .None: return MONGOC_REMOVE_NONE
        case .SingleRemove: return MONGOC_REMOVE_SINGLE_REMOVE
        }
    }
}
