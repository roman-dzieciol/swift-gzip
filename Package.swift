// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RDGZip",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9),
    ],
    products: [
        .library(
            name: "RDGZip",
            targets: ["RDGZip"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "RDGZip",
            dependencies: []),
        .testTarget(
            name: "RDGZipTests",
            dependencies: ["RDGZip"]),
    ]
)

