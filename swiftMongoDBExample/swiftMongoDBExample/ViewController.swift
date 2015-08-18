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

        let subject = MongoDocument(data: ["name" : "Dan", "age": 15, "friends": ["billy", "bob", "joe"], "location": ["lat":13, "long":15]])
        subjects.insert(subject)

        subject.printSelf()


        let results = subjects.find(["age": 15])

        if let results = results {

            print("result count: \(results.count)")

            for result in results {
                result.printSelf()
            }

        } else {
            print("Something went wrong")
        }
    }
}