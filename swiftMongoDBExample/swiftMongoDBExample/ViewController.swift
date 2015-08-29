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

        if mongodb.connectionStatus != .Success {
            print("connection was not successful")
            return
        }


        let subjects = MongoCollection(name: "subjects")
        mongodb.registerCollection(subjects)

        // method #1
        let subject1 = MongoDocument(data: ["name" : "Dan", "age": 15, "friends": ["Billy", "Bob", "Joe"], "location": ["city":"San Francisco"]])

        // method #2 (cleaner, reusable)
        struct Subject: MongoObject {
            var name = "Billy"
            var age = 15
            var friends = [
                "Dan",
                "Bob",
                "Joe"
            ]
            var location = [
                "city" : "New York"
            ]
        }
        
        let subject = Subject()
        let subject2 = subject.Document()


        subjects.insert(subject1) // insert dan
        subjects.insert(subject2) // insert billy

        subjects.remove(["_id": subject1.id!]) // remove dan

        subjects.update(query: ["name":"Dan"], document: subject2, type: .Basic) // basic = single override (non-additive)

        let results = subjects.find(["age": 15])

        switch results {

        case .Success(let testSubjects):
            print(testSubjects)
            for testSubject in testSubjects {
                testSubject.printSelf()
            }

        case .Failure(let err):
            print(err)

        }
    }
}