# SwiftMongoDB
A Swifter to work with MongoDB in Swift. Wraps around the [MongoDB C Driver v0.8](http://api.mongodb.org/c/0.8/) (using a legacy version because it has only one dependency).

[![Version](https://img.shields.io/cocoapods/v/SwiftMongoDB.svg?style=flat)](https://cocoapods.org/pods/SwiftMongoDB)
[![License](https://img.shields.io/cocoapods/l/SwiftMongoDB.svg?style=flat)](https://cocoapods.org/pods/SwiftMongoDB)
[![Platform](https://img.shields.io/cocoapods/p/SwiftMongoDB.svg?style=flat)](https://cocoapods.org/pods/SwiftMongoDB)

# Setup

If you're using cocoapods, add the following line to your Podfile. You can then proceed to either the Quickstart or Tutorial.
```ruby
pod 'SwiftMongoDB'
```

Otherwise, clone the repository, cd into the directory, and run

```bash
pod install
```

then, assuming that you have MongoDB setup, open up terminal and run:

```bash
mongod
```

You can either open the example project (same thing as the quickstart), or go through the slightly more in-depth version in the Tutorial.

# Quickstart

Make sure you have MongoDB (`mongod` in bash) running and have the library imported.

You can now paste the following code into any function and it will work. The code executes synchronously.

```swift
let mongodb = MongoDB(database: "test")

if mongodb.connectionStatus != .Success {
    print("connection was not successful")
    return
}


let subjects = MongoCollection(name: "subjects")
mongodb.registerCollection(subjects)

// method #1 (basic)
let subject1 = MongoDocument(data:
	[
		"name" : "Dan",
		"age": 15,
		"friends": [
			"Billy",
			"Bob",
			"Joe"
		],
		"location": [
			"city":"San Francisco"]
	]
)

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

subjects.update(query: ["name":"Billy"], document: subject1, type: .Basic) // replace billy with dan

let results = subjects.find(["age": 15]) // find all people aged 15 (dan)

// results is of type MongoResult, which means it is either
// .Success(result) or .Error(error)
// below is an example of how to work with it

switch results {

case .Success(let testSubjects):
    print(testSubjects)
    for testSubject in testSubjects {
    	print(testSubject.data)
    }

case .Failure(let err):
    print(err)

}

```

For some more examples, I would take a look at the 'schema' section of this readme. You can also take a look at the test suite.

# Tutorial

This example assumes that you have setup the project and have MongoDB running.

First, you need to establish a connection to the MongoDB server.

```swift
import swiftMongoDB

let mongodb = MongoDB(database: "test")
```

By default it connects to `localhost:27017` (which is what running `mongod` with no parameters defaults to). If you want to connect to a different location, you can do something like this:


```swift
let mongodb = MongoDB(host: "123.123.123.123", port: 12345, database: "test")
```

Then you need to create and register a collection. The creation part is kind of misleading since it will perform the same way whether a collection with the given name already exists or not.

```swift
let subjects = MongoCollection(name: "subjects")
mongodb.registerCollection(subjects)
```

An important part of SwiftMongoDB is how it handles inserting documents. Most of the work will be done with a medium called MongoDocument, where you're passing a `[String : AnyObject]` type dictionary and it gets converted to a MongoDB type called BSON behind the scenes (you, fortunately, don't have to worry about this).

For example, say you wanted to create a human named Dan. This is how it would look in JSON:

```json
{
	"name": "Dan",
	"age": 15,
	"friends": [
		"Billy",
		"Bob",
		"Joe"
	],
	"location": {
		"city": "San Francisco",
		"state" "California"
	}
}
```

It looks pretty similar in Swift:

```swift
let data = [
	"name": "Dan",
	"age": 15,
	"friends": [
		"Billy",
		"Bob",
		"Joe"
	],
	"location": [
		"city": "San Francisco",
		"state": "California"
	]
]

let subject = MongoDocument(data: data)
```

SwiftMongoDB provides you with another, slightly cleaner way of creating objects.

```swift
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

let subject = Subject().document()
```

You can then insert the newly created document(s) into the collection.

```swift
subjects.insert(subject)
```

That's it for inserting documents - pretty simple, right?

Now, lets do some querying!

Here's the most basic query you can possibly perform:

```swift
let result = subjects.find()
```

If you're keen and took a look at the function signature, you might notice that the result of subjects.find() actually returns a mysterious `MongoResult<[MongoDocument]>`. I'll go over what this is really quickly.

MongoResult is declared as such:

```swift
public enum MongoResult<T> {
    case Success(T)
    case Failure(NSError)
}
```

This means that the result is sort of like a promise - it can either be successful or throw an error. The way to handle these results is with a simple switch statement like this:

```swift
switch result {

case .Success(let data):
    doSomethingWithResult(data)

case .Failure(let err):
    print(err)

}
```

Which turns the original `let result = subjects.find()` into

```swift
let result = subjects.find()
switch results {

case .Success(let testSubjects):
	for testSubject in testSubjects {
		testSubject.printSelf()
	}

case .Failure(let err):
    print(err)

}
```

Hopefully this way of handling results will make it cleaner to work with SwiftMongoDB (if it isn't, let me know and I'll add alternatives).

Now, say we inserted a few more test subjects and wanted to query for all of them whose age is exactly 15. This is pretty simple:

```swift
let result = subjects.find(["age" : 15])
```

The query parameter operates just as it would in most other MongoDB implementations. For instance, in the MongoDB shell, this would be the equivalent of `db.subjects.find( {"age" : 15} )`

Removing documents works the same way - if you want to remove all humans named Dan, you simply do:

```swift
subjects.remove(["name" : "Dan"])
```

The last basic operation is update. MongoCollection.update takes 3 parameters: query, document, and type.

Query is the query by which the documents to be updated will be found.
Document is the new value that the queried will have.
Type represents the type of update which will be performed - either basic, upsert, or multi. Basic is a single replacement, upsert inserts a document if the query doesn't match anything, and multi replaces all the documents matched.

An example call might look like so:

```swift
subjects.update(query: ["name":"Dan"], document: subject, type: .Basic)
```

That code updates all people with the name "Dan" with a new subject with the update type of basic (single replacement).

Those are the basics - it's really a very small library. You can take a look at the test suite which should show you some of the methods not shown here. Otherwise, feel free to jump right into the deep end and start using SwiftMongoDB!

# Schemas

Schemas are a very powerful part of SwiftMongoDB. If you've ever used Mongoose, this might look a little familiar.

The most basic example uses a generic object with properties, which can then be inserted into a collection.

```swift
struct MyBasicObject: MongoObject {

    var _privateData: String {
        return "some computed data which will be ignored."
    }

    var prop1 = "123"
    var prop2 = 10
    var prop3 = true

    func doStuff() {
        // do stuff
    }
}

var myBasicObject = MyBasicObject()
myBasicObject.prop3 = false
// can now insert myBasicObject into a collection.
```

The next example uses protocols to define schemas to make it easier for you to create multiple objects under the same schema.

```swift
protocol MySchema: MongoObject {

    var prop1: String {get}
    var prop2: Int {get}
    var prop3: Bool {get}
}

struct MySchemadObject1: MySchema {

    var _privateData: String {
        return "Some private, hidden data."
    }

    let prop1 = "123"
    let prop2 = 10
    let prop3 = true

    func doStuff() {
        // do stuff
    }
}

struct MySchemadObject2: MySchema {

    var _privateData: String {
        return "Some private, hidden data."
    }

    var prop1 = "hello world!"
    var prop2 = 1
    var prop3 = false

    func doOtherStuff() {
        // do other stuff
    }
}

var mySchemadObject1 = MySchemadObject1()
//mySchemadObject1.prop2 = 5 cannot do
var mySchemadObject2 = MySchemadObject2()
//mySchemadObject2.prop2 = 5 can do

// can now insert mySchemadObject1, mySchemadObject2 into a collection
```

This last example takes advantages of a new feature in Swift 2 called Protocol Extensions. Essentially, it allows you to insert implementations of the protocol in the protocol itself. In SwiftMongoDB, you can use protocol extensions to define default values in your schema.

```swift
protocol MySchemaWithDefaults: MongoObject {
    var prop1: String {get}
    var prop2: Int {get}
    var prop3: Bool {get}
}

extension MySchemaWithDefaults {
    var prop1: String {
        return "hello world!"
    }

    var prop2: Int {
        return 5
    }
}

struct MyObjectWithDefaults: MySchemaWithDefaults {
    var prop2 = 7
    var prop3 = false
}

let myObjectWithDefaults = MyObjectWithDefaults()

myObjectWithDefaults.prop1 // results in default value: hello world
myObjectWithDefaults.prop2 // results in non-default value: 7
myObjectWithDefaults.prop3 // results in schema'd but not defaulted value: false

// can now insert myObjectWithDefaults into a collection.
```

Hopefully schemas will allow your code to be much more clean and strict by taking advantage of default values through protocol extensions and property-name autocomplete.

# Roadmap

[Here's the Trello board for this project](https://trello.com/b/FT2OCCjQ/swiftmongodb).

Ideally I would like to mirror all of the features that the Mongo Shell offers, and eventually add my own touch to it.

# Contributing
Any and all help is very welcome! Feel free to fork and submit a pull request - I will almost certainly merge it.

You should start by looking at the [trello board](https://trello.com/b/FT2OCCjQ/swiftmongodb) and see if there's anything you want to implement there. You can also create feature requests.

There's also a test suite included in the xcode project - so far the coverage isn't too good but it will get better, I promise.

# Changelog

## 0.1

## 0.1.0
Add documentation, clean up a lot of code, add examples for schemas using inheritence, protocols, and protocol extensions.

## 0.0

### 0.0.9 (Saturday, August 29th, 2015)
Add support for very simple mongoose-esque schemas by conforming to protocol MongoObject.

### 0.0.8 (Friday, August 28th, 2015)
Implement (untested) login, fix major issue with querying where objects would either get ignored or query would loop indefinitely.

### 0.0.7
Fix BSON encoder and decoder to support boolean values, bugfixes.

### 0.0.6
Implement BSON -> Swift, bugfixes.

### 0.0.5
Make SwiftMongoDB multiplatform.

### 0.0.4 - 0.0.2
Getting Cocoapods to work, bugfixes.

### 0.0.1
Core operations implemented (insert, find, remove).