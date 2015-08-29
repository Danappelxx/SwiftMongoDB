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

    /// The raw MongoDB connection.
    internal var connection: UnsafeMutablePointer<mongo>? = mongo_alloc()

    /// The raw database name.
    internal let databaseName: String

    /// The name of the database that was connected to (read-only).
    public var db: String {
        get {
            return self.databaseName
        }
    }

    /// A set of all the registered collections.
    internal var collections = Set<MongoCollection>()
    

    /**
    Initiates a MonogDB connection with the given parameters.
    
    - parameter host:        The host, ex: 127.0.0.1
    - parameter port:        The port, ex: 27017
    - parameter database:    The database, ex: 'test'
    - parameter userAndPass: The username and password for the user in the format (username, password) - optional.
    */
    public init(host: String, port: Int, database: String, usernameAndPassword userAndPass:(username: String, password: String)? = nil) {
        
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
        if let userAndPass = userAndPass {
            self.login(username: userAndPass.username, password: userAndPass.password)
        }
    }
    

    /**
    A function which attempts to authenticate the mongodb connection.

    - parameter username: The username of the registered user.
    - parameter password: The password of the registered user.
    
    - returns: A boolean value stating whether the login succeeded or not.
    */
    public func login(username username: String, password: String) -> Bool {
        return mongo_cmd_authenticate(self.connection!, self.db, username, password) == MONGO_OK
    }
    
    /**
    Initates the mongodb connection to the default host and port (usually localhost:27017)
    */
    public convenience init(database: String, usernameAndPassword userAndPass:(username: String, password: String)? = nil) {
        
        self.init(host: Helpers.getIPAddress(), port: 27017, database: database, usernameAndPassword: userAndPass)


        if let userAndPass = userAndPass {
            self.login(username: userAndPass.username, password: userAndPass.password)
        }
    }
    
    /**
    Deallocates the mongo connection
    */
    deinit {
        if connection != nil {
            mongo_destroy(self.connection!)
        }
    }

    /// A variable describing whether the connection failed or not. If it failed, all operations regarding MongoCollections will fail.
    private var connectionFailed = false

    /// Describes the MongoDB error in the form of a Swift enum.
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
    
    /// Returns a boolean stating whether self.connectionStatus is ConnectinStatus.Success
    public var connectionWasSuccessful: Bool {
        return self.connectionStatus == ConnectionStatus.Success
    }
    
    /**
    Registeres a MongoCollection. Alternatively the collection can be initialized with a MongoDB instance.
    
    - parameter collection: The MongoCollection to be registered.
    */
    public func registerCollection(collection: MongoCollection) {

        collection.connection = self.connection
        collection.databaseName = self.databaseName

        self.collections.insert(collection)
    }

    /**
    A function which will attempt to create a user in the current MongoDB database.
    
    - parameter username: The username of the created user.
    - parameter password: The password of the created user.
    
    - returns: Returns a boolean value stating whether the user registration succeeded or not.
    */
    public func createUser(username user: String, password: String) -> Bool {

        let addUserResult = mongo_cmd_add_user(self.connection!, self.db, user, password)
        print(addUserResult)
        
        return (addUserResult == MONGO_OK)
    }
}


/**
An enum with the possible success/error values for a MongoDB connection.
*/
public enum ConnectionStatus: String {
    case Success = "Successful connection"
    case NoSocket = "No socket"
    case Fail = "Connection fail"
    case NotMaster = "Not master"
    
    case Unexpected = "Unexpected error"
}