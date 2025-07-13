// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreNFCPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "CoreNFCPackage",
            targets: ["CoreNFCPackage"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CoreNFCPackage",
            dependencies: [
            ]
        ),
    ]
)
