# SwiftMongoDB [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Join the chat at https://gitter.im/Danappelxx/SwiftMongoDB](https://img.shields.io/badge/gitter-join%20chat-blue.svg)](https://gitter.im/Danappelxx/SwiftMongoDB?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Travis CI](https://api.travis-ci.org/Danappelxx/SwiftMongoDB.svg)](https://travis-ci.org/Danappelxx/SwiftMongoDB) [![codecov.io](https://codecov.io/github/Danappelxx/SwiftMongoDB/coverage.svg?branch=master)](https://codecov.io/github/Danappelxx/SwiftMongoDB?branch=master)
A Swifter way to work with MongoDB in Swift. Wraps around the [MongoDB C Driver 1.2.0](http://api.mongodb.org/c/1.2.0/) (supports MongoDB version 2.4 and later).

# Setup
The simplest and linux-compatible way to use SwiftMongoDB is through the official Swift package manager. Simply add it to your `Package.swift` like so:

```swift
import PackageDescription
let package = Package(
  name: "foo",
  dependencies: [
    .Package(url: "https://github.com/Danappelxx/SwiftMongoDB", majorVersion: 0, minor: 4)
  ]
)
```

# Tutorial
This example assumes that you have setup the project and have MongoDB running.

## Setup
At the top of any file where you use SwiftMongoDB, you need to import it:

```swift
import MongoDB
```

First, you need to establish a connection to the MongoDB server.

```swift
let client = try Client(host: "localhost", port: 27017)
```

You can connect to a MongoDB instance (local or not) this way.

Then you need to create a database.

```swift
let testDatabase = Database(client: client, name: "test")
```

Then you need to create a collection. The collection doesn't have to exist (it will be created automatically if it isn't).

```swift
let subjects = Collection(database: testDatabase, name: "subjects")
```

## Insertion and BSON
An important aspect of SwiftMongoDB is how it handles inserting documents. Most of the work will be done through a medium defined in [BinaryJSON](https://github.com/danappelxx/BinaryJSON) called `BSON.Document`. Creating it is very simple and type-safe, and the translation to MongoDB's lower-level type known as BSON is (fortunately) done behind the scenes for you.

For example, say you wanted to create a human named Dan. This is how it would look in JSON:

```json
{
  "name" : "Dan",
  "age" : 15,
  "lovesSwift" : true,
  "location" : {
    "state" : "California"
  },
  "favoriteNumbers" : [1, 2, 3, 4, 5]
}
```

It looks pretty similar in Swift:

```swift
let subject: BSON.Document = [
    "name": "Dan",
    "age": 15,
    "lovesSwift" : true,
    "location": [
        "state": "California"
    ],
    "favoriteNumbers" : [1,2,3,4,5]
]
```

You can then insert the newly created document(s) into the collection.

```swift
try subjects.insert(subject)
```

If you want to create a `BSON.Document` from JSON, it's just as simple:

```swift
let document = try BSON.fromJSONString(jsonString)
```

That's it for inserting documents - pretty neat, right?

## Querying
Now, lets do some querying!

Here's the most basic query you can possibly perform:

```swift
let cursor = try subjects.find()
let testSubjects = try cursor.all()
```

The first line, as you can see, returns a cursor. The `Cursor` type gives you more control over how you process the results of the query. For most use cases, the methods `Cursor.nextDocument` and `Cursor.all` will be enough. However, `Cursor` also conforms to `GeneratorType` and `SequenceType`, meaning that you can take advantage of a lot of neat Swift features. For example, you can iterate directly over it using a for loop:

```swift
let results = try subjects.find()
for subject in results {
    print(subject)
}
```

Now, say we inserted a few more test subjects and wanted to query for all of them whose age is exactly 15. This is pretty simple:

```swift
let result = try subjects.find(query: ["age" : 15])
```

The query parameter operates just as it would in most other MongoDB implementations. For instance, in the MongoDB shell, this would be the equivalent of `db.subjects.find( {"age" : 15} )`.

## Updating
If you wanted to change all test subjects who loved Swift to Chris Lattner, you could simply do:

```swift
let newDocument: BSON.Document = [
    "name": "Chris Lattner" // we can ignore the other keys for this example
]
try subjects.update(query: ["lovesSwift": true], newValue: newDocument)
```

## Removing
Removing documents works the same way - if you want to remove all of the test subjects named Dan, you simply do:

```swift
try subjects.remove(query: ["name" : "Dan"])
```

Those are the basics - it's really a very small simple library. You can take a look at the test suite and/or source which should show you some of the methods not shown here. Otherwise, feel free to jump right into the deep end and start using SwiftMongoDB!

# Contributing
Any and all help is very welcome! Feel free to fork and submit a pull request - I will almost certainly merge it.

You should start by taking a look at the current issues and see if there's anything you want to implement/fix there.

# License
MIT - more information is in the LICENSE file.

# Changelog
## 0.5
### 0.5.0
Swift 3 support

## 0.4
### 0.4.1
Minor api fixes

### 0.4.0
A large refactor with a cleaner API and better internal code.

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
