// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


private struct SWGZip {
    static let name = "SWGZip"
}

let package = Package(
    name: SWGZip.name,
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9),
    ],
    products: [
        .library(
            name: SWGZip.name,
            targets: [SWGZip.name]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: SWGZip.name,
            dependencies: []),
        .testTarget(
            name: SWGZip.name + "Tests",
            dependencies: [.target(name: SWGZip.name)]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)

