// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Legatus",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "Legatus",
            targets: ["Legatus"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: Version("5.0.0"))),
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", .upToNextMajor(from: Version("7.0.0")))
    ],
    targets: [
        .target(
            name: "Legatus",
            dependencies: ["Alamofire", "SWXMLHash"]),
        .testTarget(
            name: "LegatusTests",
            dependencies: ["Legatus"])
    ],
    swiftLanguageVersions: [.v5]
)
