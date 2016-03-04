# SwiftMongoDB [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Join the chat at https://gitter.im/Danappelxx/SwiftMongoDB](https://img.shields.io/badge/gitter-join%20chat-blue.svg)](https://gitter.im/Danappelxx/SwiftMongoDB?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Travis CI](https://api.travis-ci.org/Danappelxx/SwiftMongoDB.svg)](https://travis-ci.org/Danappelxx/SwiftMongoDB) [![codecov.io](https://codecov.io/github/Danappelxx/SwiftMongoDB/coverage.svg?branch=master)](https://codecov.io/github/Danappelxx/SwiftMongoDB?branch=master)
A Swifter way to work with MongoDB in Swift. Wraps around the [MongoDB C Driver 1.2.0](http://api.mongodb.org/c/1.2.0/) (supports MongoDB version 2.4 and later).

# Setup
The simplest and linux-compatible way to use SwiftMongoDB is through the official Swift package manager. Simply add it to your `Package.swift` like so:

```swift
import PackageDescription
let package = Package(
  name: "foo",
  dependencies: [
    .Package(url: "https://github.com/Danappelxx/SwiftMongoDB", majorVersion: 0, minor: 3)
  ]
)
```

If you want to use Carthage, all you have to do is add the following to your Cartfile:

```
github "Danappelxx/SwiftMongoDB"
```

and then run:

```
$ carthage bootstrap
```

This gives you a built `SwiftMongoDB.framework` in `Carthage/Build/Mac`. For instructions on how to use it, refer to the [Carthage README](https://github.com/Carthage/Carthage).

# Tutorial
This example assumes that you have setup the project and have MongoDB running.

First, you need to establish a connection to the MongoDB server.

```swift
let client = try MongoClient(host: "localhost", port: 27017, database: "test")
```

You can connect to a MongoDB instance (local or not) this way.

Then you need to create a collection. The collection doesn't have to exist (it will be created automatically if it isn't).

```swift
let subjects = MongoCollection(collectionName: "subjects", client: client)
```

An important aspect of SwiftMongoDB is how it handles inserting documents. Most of the work will be done with a medium called MongoDocument, where you insert either a `[String:BSON]` type dictionary or a JSON string. It then gets converted to a lower level type called BSON behind the scenes (you, fortunately, don't have to worry about this).

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
