import PackageDescription

let package = Package(
    name: "SwiftMongoDB",
    dependencies: [
        .Package(url: "https://github.com/Danappelxx/CMongoC.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/PureSwift/BinaryJSON", majorVersion: 0, minor: 9)
    ]
)
