// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "sealed2msg",
  platforms: [
    .macOS(.v15)
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.59.1"),
    .package(path: "../../.."),
  ],
  targets: [
    .executableTarget(
      name: "sealed2msg",
      dependencies: [
        .product(name: "SealMessage", package: "sw-seal-msg")
      ],
      swiftSettings: [
        .unsafeFlags(
          ["-cross-module-optimization"],
          .when(configuration: .release),
        )
      ],
    )
  ]
)
