// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "swift-entity-client",
  platforms: [
    .iOS(.v16),
    .macCatalyst(.v18),
    .macOS(.v15),
    .tvOS(.v17),
    .visionOS(.v2),
    .watchOS(.v11),
  ],
  products: [
    .library(name: "EntityClient", targets: ["EntityClient"]),
    .library(name: "EntityClientCloudFileClient", targets: ["EntityClientCloudFileClient"]),
    .library(name: "EntityClientMongoDB", targets: ["EntityClientMongoDB"]),
  ]
)

package.dependencies = [
  .package(url: "https://github.com/AlexKobachiJP/swift-extensions", from: "0.3.9"),
  .package(url: "https://github.com/AlexKobachiJP/swift-cloud-file-client", from: "0.1.1"),
  .package(url: "https://github.com/AlexKobachiJP/swift-crypto-helpers", from: "0.2.0"),
  .package(url: "https://github.com/AlexKobachiJP/swift-file-location", from: "0.3.8"),
  .package(url: "https://github.com/AlexKobachiJP/swift-json-helpers", from: "0.1.13"),
  .package(url: "https://github.com/mongodb/mongo-swift-driver", from: "1.3.1"),
]

package.targets = [
  .target(
    name: "EntityClient",
    dependencies: [
      .product(name: "CloudFileClient", package: "swift-cloud-file-client"),
      .product(name: "FileHasher", package: "swift-crypto-helpers"),
      .product(name: "FileLocation", package: "swift-file-location"),
      .product(name: "SwiftExtensions", package: "swift-extensions"),
      .product(name: "JsonHelpers", package: "swift-json-helpers"),
    ]
  ),
  .testTarget(
    name: "EntityClientTests",
    dependencies: ["EntityClient"]
  ),

  .target(
    name: "EntityClientCloudFileClient",
    dependencies: [
      "EntityClient",
    ]
  ),
  
  .target(
    name: "EntityClientMongoDB",
    dependencies: [
      "EntityClient",
      .product(name: "MongoSwift", package: "mongo-swift-driver"),
    ]
  ),
]

// MARK: - Common Dependencies

package.dependencies += [
  .package(url: "https://github.com/AlexKobachiJP/swift-testing-toolbox", from: "0.1.0")
]

for target in package.targets where target.isTest {
  target.dependencies += [
    .product(name: "TestingToolbox", package: "swift-testing-toolbox")
  ]
}

// MARK: - Swift Settings

for target in package.targets where target.type != .binary {
  var swiftSettings = target.swiftSettings ?? []

  // Swift 6
  #if !hasFeature(AccessLevelOnImport)
    swiftSettings.append(.enableExperimentalFeature("AccessLevelOnImport"))
  #endif

  #if !hasFeature(InternalImportsByDefault)
    swiftSettings.append(.enableUpcomingFeature("InternalImportsByDefault"))
  #endif

  // Swift 7
  #if !hasFeature(ExistentialAny)
    swiftSettings.append(.enableUpcomingFeature("ExistentialAny"))
  #endif

  target.swiftSettings = swiftSettings
}
