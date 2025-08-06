// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "RedisOM",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "RedisOM",
            targets: ["RedisOM"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/RediStack.git", from: "1.4.1"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),

    ],
    targets: [
        .target(
            name: "RedisOM",
            dependencies: [
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(
            name: "RedisOMTests",
            dependencies: [
                .target(name: "RedisOM"),
                .product(name: "VaporTesting", package: "vapor")
            ]
        ),
    ]
)
