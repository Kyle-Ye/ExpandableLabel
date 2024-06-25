// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExpandableLabel",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "ExpandableLabel",
            targets: ["ExpandableLabel"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Kyle-Ye/YYText.git", from: "1.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
    ],
    targets: [
        .target(
            name: "ExpandableLabel",
            dependencies: [
                .product(name: "YYText", package: "YYText"),
                .product(name: "SnapKit", package: "SnapKit"),
            ]
        ),
    ]
)
