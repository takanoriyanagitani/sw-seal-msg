// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "SealMessage",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "SealMessage",
      targets: ["SealMessage"])
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.59.1"),
    .package(
      url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.4",
    ),
  ],
  targets: [
    .target(
      name: "SealMessage"),
    .testTarget(
      name: "SealMessageTests",
      dependencies: ["SealMessage"]
    ),
  ]
)
