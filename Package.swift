import PackageDescription

let package = Package(
    name: "MongoDB",
    dependencies: [
        .Package(url: "https://github.com/PureSwift/CBSON.git", majorVersion: 1),
        .Package(url: "https://github.com/Danappelxx/CMongoC.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/Danappelxx/BinaryJSON", majorVersion: 1, minor: 1)
    ]
)