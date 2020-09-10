// swift-tools-version:5.1
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
        .package(url: "https://github.com/Alamofire/Alamofire.git", .exact("5.2.2")),
        .package(url: "https://github.com/delba/JASON.git", .branch("master")),
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", .exact("5.0.1"))
    ],
    targets: [
        .target(
            name: "Legatus",
            dependencies: ["Alamofire", "JASON", "SWXMLHash"]),
        .testTarget(
            name: "LegatusTests",
            dependencies: ["Legatus"])
    ],
    swiftLanguageVersions: [.v5]
)
