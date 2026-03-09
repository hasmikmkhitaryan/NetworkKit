// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "NetworkKit",
    platforms: [
        .macOS(.v15), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(name: "NetworkKit", targets: ["NetworkKit"]),
    ],
    targets: [
        .target(name: "NetworkKit", dependencies: []),
        .testTarget(name: "NetworkKitTests", dependencies: ["NetworkKit"]),
    ]
)
