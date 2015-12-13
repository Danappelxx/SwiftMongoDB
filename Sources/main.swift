import CMongoC

let client = try MongoClient(host: "localhost", port: 27017)

print("running")
let names = try client.getDatabaseNames()
print(names)
