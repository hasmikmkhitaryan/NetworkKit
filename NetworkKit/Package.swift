// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "NetworkKit",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(name: "NetworkKit", targets: ["NetworkKit"]),
    ],
    targets: [
        .target(name: "NetworkKit", dependencies: []),
        .testTarget(name: "NetworkKitTests", dependencies: ["NetworkKit"]),
    ]
)
