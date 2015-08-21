//
//  ViewController.swift
//  swiftMongoDBExample
//
//  Created by Dan Appel on 8/14/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

import Cocoa
import swiftMongoDB

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let mongodb = MongoDB(database: "test")
        print(mongodb.connectionStatus)


        let subjects = MongoCollection(name: "subjects")
        mongodb.registerCollection(subjects)

        let subject1 = MongoDocument(data: ["name" : "Dan", "age": 15, "friends": ["Billy", "Bob", "Joe"], "location": ["city":"San Francisco"]])
        let subject2 = MongoDocument(data: ["name" : "Billy", "age": 16, "friends": ["Dan", "Bob", "Joe"], "location": ["city":"New York"]])

        subjects.insert(subject1)
        subjects.insert(subject2)

        subjects.remove(["age": 16])


        let results = subjects.find(["age": 15])

        switch results {

        case .Success(let testSubjects):
            print(testSubjects)

        case .Failure(let err):
            print(err)

        }
//        if let results = results {
//
//            print("result count: \(results.count)")
//
//            for result in results {
//                result.printSelf()
//            }
//        }
    }
}