//
//  helpers.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/14/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation

class Helpers {
    static func getIPAddress() -> String {
            
            var addresses = NSHost.currentHost().addresses
            if addresses.count > 1 {
                return addresses[1]
            }
            
            return "127.0.0.1"
    }
}