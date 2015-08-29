//
//  MongoObject.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/28/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation


/**
*  A protocol that allows your objects
*/
public protocol MongoObject {

    func Document() -> MongoDocument
    func properties() -> DocumentData
}

public extension MongoObject {

    /**
    - returns: Returns a MongoDocument initialized from the Schema.
    */
    func Document() -> MongoDocument {
        return MongoDocument(withSchemaObject: self)
    }
    
    /**
    - returns: Returns each of the properties of class in the form of DocumentData ([String : AnyObject])
    */
    func properties() -> DocumentData {
        
        var children = DocumentData()
        
        for child in Mirror(reflecting: self).children {
            
            if let label = child.label {
                if let value = child.value as? AnyObject {
                    children[label] = value
                }
            }
        }
        
        return children
    }
}