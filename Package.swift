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
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "4.9.1")),
        .package(url: "https://github.com/delba/JASON.git", .branch("master")),
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", .branch("master"))
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
