# SwiftMongoDB
A Swifter to work with MongoDB in Swift. Wraps around the [MongoDB C Driver 1.2.0](http://api.mongodb.org/c/1.2.0/) (supports MongoDB version 2.4 and later).

[![Version](https://img.shields.io/cocoapods/v/SwiftMongoDB.svg?style=flat)](https://cocoapods.org/pods/SwiftMongoDB) [![License](https://img.shields.io/cocoapods/l/SwiftMongoDB.svg?style=flat)](https://cocoapods.org/pods/SwiftMongoDB) [![Platform](https://img.shields.io/cocoapods/p/SwiftMongoDB.svg?style=flat)](https://cocoapods.org/pods/SwiftMongoDB)

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

// assumes you have mongod running
// using Swift 2 error handling model (methods can throw errors)
do {
  let client = try! MongoClient(host: "localhost", port: 27017, database: "test")

  let subjects = MongoCollection(collectionName: "subjects", client: client)

  // method #1, basic
  let testSubject1 = MongoDocument(data: [
    "name" : "Dan",
    "age" : 15,
    "lovesProgramming" : true,
    "location" : [
      "general_area" : "SF Bay Area",
      "state" : "California"
    ],
    "favorite_numbers" : [1, 2, 3, 4, 5]
  ])

  // method #2, cleaner (better)
  struct TestSubject: MongoObject {
    let name = "Dan"
    let age = 15
    let lovesProgramming = true
    let location = [
      "general_area" : "SF Bay Area",
      "state" : "California"
    ]
    let favorite_numbers = [1, 2, 3, 4, 5]
  }

  let testSubject2 = TestSubject().Document()

  try subjects.insert(testSubject1)
  try subjects.insert(testSubject2)

  let testSubjects = try subjects.find()
  let testSubjectsData = testSubjects.map { $0.data }
  print(testSubjectsData)

  try testSubjects.remove(testSubject1.data)

} catch {
  print(error)
}
```

For some more examples, I would take a look at the 'schema' section of this readme. You can also take a look at the test suite.

# Tutorial
This example assumes that you have setup the project and have MongoDB running.

First, you need to establish a connection to the MongoDB server.

```swift
let client = try MongoClient(host: "localhost", port: 27017, database: "test")
```

If you have a keen eye you may have noticed the `try` keyword. This is due to SwiftMongoDB using the Swift 2 error handling model. What this means is that most methods need to be wrapped in a `do {}` block, with an optional `catch {}` block afterwards (this won't be shown, but will be assumed). Hopefully this will make working with SwiftMongoDB cleaner and more predictable.

You can connect to a MongoDB instance (local or not) this way.

Then you need to pick a collection. The collection doesn't have to exist (it will be created automatically if it isn't).

```swift
let subjects = MongoCollection(collectionName: "subjects", client: client)
```

An important aspect of SwiftMongoDB is how it handles inserting documents. Most of the work will be done with a medium called MongoDocument, where you insert either a `[String : AnyObject]` type dictionary, a JSON string, or from a mongoose-like schema. It then gets converted to a MongoDB type called BSON behind the scenes (you, fortunately, don't have to worry about this).

For example, say you wanted to create a human named Dan. This is how it would look in JSON:

```json
{
  "name" : "Dan",
  "age" : 15,
  "lovesProgramming" : true,
  "location" : {
    "general_area" : "SF Bay Area",
    "state" : "California"
  },
  "favorite_numbers" : [1, 2, 3, 4, 5]
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

let subject = MongoDocument(data)
```

Either of those will work, but SwiftMongoDB provides you with a third, cleaner option that is similar to a schema. All you have to do is create a struct, class, or protocol that conforms to MongoObject.

```swift
struct TestSubject: MongoObject {
  let name = "Dan"
  let age = 15
  let lovesProgramming = true
  let location = [
    "general_area" : "SF Bay Area",
    "state" : "California"
  ]
  let favorite_numbers = [1, 2, 3, 4, 5]
}

let subject = TestSubject().Document()
```

You can then insert the newly created document(s) into the collection.

```swift
subjects.insert(subject)
```

That's it for inserting documents - pretty neat, right?

Now, lets do some querying!

Here's the most basic query you can possibly perform:

```swift
let result = subjects.find()
```

Now, say we inserted a few more test subjects and wanted to query for all of them whose age is exactly 15. This is pretty simple:

```swift
let result = try subjects.find(["age" : 15])
```

The query parameter operates just as it would in most other MongoDB implementations. For instance, in the MongoDB shell, this would be the equivalent of `db.subjects.find( {"age" : 15} )`.

Removing documents works the same way - if you want to remove all humans named Dan, you simply do:

```swift
try subjects.remove(["name" : "Dan"])
```

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
## 0.2
### 0.2.0 (September 8th, 2015)
Migrate to MongoDB C Driver 1.2.0 from 0.8, comes with a complete rewrite

## 0.1
### 0.1.1
Migrate to Swift 2 error handling model

### 0.1.0
Add documentation, clean up a lot of code, add examples for schemas using inheritence, protocols, and protocol extensions.

## 0.0
### 0.0.9 (August 29th, 2015)
Add support for very simple mongoose-esque schemas by conforming to protocol MongoObject.

### 0.0.8 (August 28th, 2015)
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
