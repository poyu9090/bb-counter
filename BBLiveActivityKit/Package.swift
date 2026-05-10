// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BBLiveActivityKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BBLiveActivityKit", targets: ["BBLiveActivityKit"])
    ],
    targets: [
        .target(
            name: "BBLiveActivityKit",
            dependencies: []
        )
    ]
)
