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
    
    internal var connection = mongo_alloc()
    
    public var databaseName: String
    internal var collections = Set<MongoCollection>()
    
    /**
    Initiates a mongodb connection to the given host and ports.
    */
    public init(host: String, port: Int, database: String) {
        
        mongo_init(self.connection)
        
        let status = mongo_client(self.connection, host, Int32(port))
        
        if status != MONGO_OK {
            print("shitshitshit")
        }
        
        self.databaseName = database
    }
    
    /**
    Initates the mongodb connection to the default host and port (usually localhost:27017)
    */
    public convenience init(database: String) {
        
        self.init(host: Helpers.getIPAddress(), port: 27017, database: database)
        
    }
    
    /**
    Deallocates the mongo connection
    */
    deinit {
        mongo_destroy(self.connection)
    }
    
    public enum ConnectionStatus: String {
        case Success = "Successful connection"
        case NoSocket = "No socket"
        case Fail = "Connection fail"
        case NotMaster = "Not master"
        
        case Unexpected = "Unexpected error"
    }
    
    /// Returns the status of the mongodb connection
    public var connectionStatus: ConnectionStatus {
        
        switch connection.memory.err.rawValue {
            
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
