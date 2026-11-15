// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "ShipBookSDK",
    platforms: [.iOS(.v12), .tvOS(.v12)],
    products: [
        .library(
            name: "ShipBookSDK",
            targets: ["ShipBookSDK"]),
    ],
    targets: [
        .target(
            name: "ShipBookSDK",
            dependencies: [],
            path: "ShipBookSDK/Classes",
            swiftSettings: [.swiftLanguageMode(.v5)]
          ),
        .testTarget(
            name: "ShipBookSDKTests",
            dependencies: ["ShipBookSDK"],
            path: "Tests",
            swiftSettings: [.swiftLanguageMode(.v5)]
          ),
    ]
)
