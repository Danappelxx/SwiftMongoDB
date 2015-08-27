//
//  MongoDB.swift
//  swiftMongoDB
//
//  Created by Dan Appel on 8/20/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Foundation
import mongo_c_driver

// MARK: - MongoDB
public class MongoDB {
    
    internal var connection: UnsafeMutablePointer<mongo>? = mongo_alloc()

    public var databaseName: String
    internal var collections = Set<MongoCollection>()
    

    /**
    Initiates a MonogDB connection with the given parameters.
    
    - parameter host:        The host, ex: 127.0.0.1
    - parameter port:        The port, ex: 27017
    - parameter database:    The database, ex: 'test'
    - parameter userAndPass: The username and password for the user in the format (username, password) - optional.
    */
    public init(host: String, port: Int, database: String, usernameAndPassword userAndPass:(String,String)? = nil) {
        
        mongo_init(self.connection!)


        let status = mongo_client(self.connection!, host, Int32(port))
        
        if status != MONGO_OK {
            print("connection failed")
            mongo_destroy(self.connection!)
            self.connection = nil
            self.connectionFailed = true
        }

        self.databaseName = database


        // implement this later
//        if let userAndPass = userAndPass {
//            
//            mongo_cmd_authenticate(self.connection!, self.databaseName, userAndPass.0, userAndPass.1)
//        }
    }
    
    /**
    Initates the mongodb connection to the default host and port (usually localhost:27017)
    */
    public convenience init(database: String, usernameAndPassword userAndPass:(String,String)? = nil) {
        
        self.init(host: Helpers.getIPAddress(), port: 27017, database: database, usernameAndPassword: userAndPass)
        
    }
    
    /**
    Deallocates the mongo connection
    */
    deinit {
        if connection != nil {
            mongo_destroy(self.connection!)
        }
    }
    
    public enum ConnectionStatus: String {
        case Success = "Successful connection"
        case NoSocket = "No socket"
        case Fail = "Connection fail"
        case NotMaster = "Not master"
        
        case Unexpected = "Unexpected error"
    }

    
    private var connectionFailed = false

    /// Returns the status of the mongodb connection
    public var connectionStatus: ConnectionStatus {

        if self.connectionFailed {
            return ConnectionStatus.Fail
        }
        
        switch connection!.memory.err.rawValue {
            
        case MONGO_CONN_SUCCESS.rawValue:
            return ConnectionStatus.Success
            
        case MONGO_CONN_NO_SOCKET.rawValue:
            return ConnectionStatus.NoSocket
            
        case MONGO_CONN_FAIL.rawValue:
            return ConnectionStatus.Fail
            
        case MONGO_CONN_NOT_MASTER.rawValue:
            return ConnectionStatus.NotMaster
            
        default:
            return ConnectionStatus.Unexpected
            
        }
    }
    
    public var connectionWasSuccessful: Bool {
        return self.connectionStatus == ConnectionStatus.Success
    }
    
    public func registerCollection(collection: MongoCollection) {

        collection.connection = self.connection
        collection.databaseName = self.databaseName

        self.collections.insert(collection)
    }
}
