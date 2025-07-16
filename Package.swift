// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "RedisOM",
    products: [
        .library(
            name: "RedisOM",
            targets: ["RedisOM"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/RediStack.git", from: "1.4.1")
    ],
    targets: [
        .target(
            name: "RedisOM",
            dependencies: [
                .product(name: "RediStack", package: "RediStack"),
            ]
        ),
        .testTarget(
            name: "RedisOMTests",
            dependencies: ["RedisOM"]
        ),
    ]
)
