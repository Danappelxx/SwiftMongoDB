import CMongoC

let client = try MongoClient(host: "localhost", port: 27017)

let names = try client.getDatabaseNames()
print(names)
