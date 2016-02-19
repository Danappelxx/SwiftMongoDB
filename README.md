# SwiftMongoDB [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Join the chat at https://gitter.im/Danappelxx/SwiftMongoDB](https://img.shields.io/badge/gitter-join%20chat-blue.svg)](https://gitter.im/Danappelxx/SwiftMongoDB?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Travis CI](https://api.travis-ci.org/Danappelxx/SwiftMongoDB.svg)](https://travis-ci.org/Danappelxx/SwiftMongoDB) [![codecov.io](https://codecov.io/github/Danappelxx/SwiftMongoDB/coverage.svg?branch=master)](https://codecov.io/github/Danappelxx/SwiftMongoDB?branch=master)
A Swifter way to work with MongoDB in Swift. Wraps around the [MongoDB C Driver 1.2.0](http://api.mongodb.org/c/1.2.0/) (supports MongoDB version 2.4 and later).

# Setup
The simplest way to use SwiftMongoDB is through Carthage.

All you have to do is add the following to your Cartfile:

```
github "Danappelxx/SwiftMongoDB"
```

and then run:

```
$ carthage bootstrap
```

This gives you a built `SwiftMongoDB.framework` in `Carthage/Build/Mac`. For instructions on how to use it, refer to the [Carthage README](https://github.com/Carthage/Carthage) You can now proceed to read through the tutorial.

# Example
There is an example application [here](https://github.com/Danappelxx/MongoDBExplorer). It's probably better to read the rest of the README first, though.

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

An important aspect of SwiftMongoDB is how it handles inserting documents. Most of the work will be done with a medium called MongoDocument, where you insert either a `[String : AnyObject]` type dictionary, a JSON string, or from a mongoose-like schema. It then gets converted to a lower level type called BSON behind the scenes (you, fortunately, don't have to worry about this).

For example, say you wanted to create a human named Dan. This is how it would look in JSON:

```json
{
  "name" : "Dan",
  "age" : 15,
  "lovesProgramming" : true,
  "location" : {
    "state" : "California"
  },
  "favoriteNumbers" : [1, 2, 3, 4, 5]
}
```

It looks pretty similar in Swift:

```swift
let data = [
    "name": "Dan",
    "age": 15,
    "lovesProgramming" : true,
    "location": [
        "state": "California"
    ]
    "favoriteNumbers" : [1,2,3,4,5]
]

let subject = MongoDocument(data)
```

And the (much cleaner) schema option which SwiftMongoDB provides you with looks like this. All you have to do is create a struct, class, or protocol that conforms to the type `MongoObject`. For more information about schemas, visit the schema section of this README.

```swift
struct TestSubject: MongoObject {
  let name = "Dan"
  let age = 15
  let lovesProgramming = true
  let friends = [
    "Billy",
    "Bob",
    "Joe"
  ]
  let location = [
    "state" : "California"
  ]
  let favoriteNumbers = [1,2,3,4,5]
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

Removing documents works the same way - if you want to remove all of the test subjects named Dan, you simply do:

```swift
try subjects.remove(["name" : "Dan"])
```

Those are the basics - it's really a very small simple library. You can take a look at the test suite which should show you some of the methods not shown here. Otherwise, feel free to jump right into the deep end and start using SwiftMongoDB!

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
Ideally I would like to mirror all of the features that the Mongo Shell/drivers offer, and eventually add my own touch to it.

# Contributing
Any and all help is very welcome! Feel free to fork and submit a pull request - I will almost certainly merge it.

You should start by taking a look at the current issues and see if there's anything you want to implement/fix there.

# Changelog
## 0.3
### 0.3.0 
SPM and Linux support

## 0.2
### 0.2.3
Update dependencies, fix a few bugs.

### 0.2.2
Update dependencies.

### 0.2.1
Set up proper dependency management through Carthage, among other fixes.

### 0.2.0
Migrate to MongoDB C Driver 1.2.0 from 0.8, comes with a complete rewrite

## 0.1
### 0.1.1
Migrate to Swift 2 error handling model

### 0.1.0
Add documentation, clean up a lot of code, add examples for schemas using inheritance, protocols, and protocol extensions.

## 0.0
### 0.0.9
Add support for very simple mongoose-esque schemas by conforming to protocol MongoObject.

### 0.0.8
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
