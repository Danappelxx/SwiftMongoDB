import CMongoC

let client = try MongoClient(host: "localhost", port: 27017)

print("up and running")

let names = try client.getDatabaseNames()
print(names)

let database = MongoDatabase(client: client, name: "test")
print(database.name)

let collection = MongoCollection(name: "subjects", database: database)
do {
    print(try collection.find().map { $0.data })
    try collection.insert(["name":.String("dan")])
    print(try collection.find().map { $0.data })
} catch {
    print(error)
}
