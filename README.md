# SwiftMongoDB
A Swifter to work with MongoDB in Swift

# Quickstart
Clone the repository, cd into the directory, and run
```bash
pod install
```

Afterwards, assuming that you have MongoDB setup, open up terminal and run:
```bash
mongod
```

You can then open up Xcode (this project is written with Xcode 7 Beta 5 - I cannot guarantee it will work on other versions) and run the example project.

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

# Contributing
Any and all help is very welcome! Feel free to fork and submit a pull request - I will almost certainly merge it.
