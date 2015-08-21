//
//  MongoError.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

class MongoError {

    let error: NSError
    private let domain = "SwiftMongoDB"

    init(code: Int, userInfo: [NSObject:AnyObject]?) {
        self.error = NSError(domain: self.domain, code: code, userInfo: userInfo)
    }

    convenience init() {
        self.init(code: 400, userInfo: nil)
    }
    
    convenience init(code: Int) {
        self.init(code: code, userInfo: nil)
    }

    convenience init(info: [NSObject:AnyObject]) {
        self.init(code: 400, userInfo: info)
    }
}