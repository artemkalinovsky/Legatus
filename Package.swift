// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Legatus",
    platforms: [.macOS(.v10_15),
                .iOS(.v13),
                .tvOS(.v13),
                .watchOS(.v5)],
    products: [
        .library(
            name: "Legatus",
            targets: ["Legatus"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .exactItem(Version("5.6.1"))),
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", .exactItem(Version("6.0.0")))
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
