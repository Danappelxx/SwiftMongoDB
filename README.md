# SwiftMongoDB
A Swifter to work with MongoDB in Swift

# Setup

Clone the repository, cd into the directory, and run

```bash
pod install
```

Afterwards, assuming that you have MongoDB setup, open up terminal and run:

```bash
mongod
```

You can then open up Xcode (this project is written with Xcode 7 Beta 5 - I cannot guarantee it will work on other versions) and run the example project.

If you don't want to use the example project (or don't feel like opening up that file), see the following section.

# Quickstart

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

Pretty standard stuff - it looks pretty similar in Swift.

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

Fairly straight-forward. The only part that can get confusing is when worthing with nested objects, but that's more of a readability issue.

You can then insert the newly created document into the collection.

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

Removing documents works the same way - you can either remove all of them with

```swift
subjects.remove()
```

or only remove those whose name is Dan, for example, with:

```swift
subjects.remove(["name" : "Dan"])
```

That's about it for now! More operations will be supported in the future.


# Features
Most of the features will be shown in the example project. As of now, the features supported are:
* Connecting to the MongoDB database
* Creation of collections
* Creation of documents
* Inserting documents into collections
* Querying for documents (find) in collections
* Removing documents from collections (with query)

# Roadmap
Ideally I would like to mirror all of the features that the Mongo Shell offers, and eventually more.

Currently in sight:
* Remove
* Update
* MongoDB selectors
* Create a document from a SwiftyJSON object

# Contributing
Any and all help is very welcome! Feel free to fork and submit a pull request - I will almost certainly merge it.
