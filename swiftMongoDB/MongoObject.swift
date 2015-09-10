//
//  MongoObject.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/28/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation


/**
*  A protocol that allows documents to be described in an Object Orientated way.
*/
public protocol MongoObject {

    func Document(containsObjectID: Bool) -> MongoDocument
    func properties() -> DocumentData
}

public extension MongoObject {

    /**
    - returns: Returns a MongoDocument initialized from the Schema.
    */
    func Document(containsObjectId: Bool = false) -> MongoDocument {
        return try! MongoDocument(withSchemaObject: self, containsObjectId: containsObjectId)
    }
    
    /**
    - returns: Returns each of the properties of class in the form of DocumentData ([String : AnyObject])
    */
    func properties() -> DocumentData {
        
        var children = DocumentData()
        
        for child in Mirror(reflecting: self).children {
            
            if let label = child.label {

                if label.characters[label.startIndex] != "_" {
                
                    if let value = child.value as? AnyObject {
                        children[label] = value
                    }
                }
            }
        }
        return children
    }
}