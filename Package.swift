// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
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
        .package(url: "https://github.com/apple/swift-syntax.git", from: "602.0.0"),

    ],
    targets: [
        .macro(
            name: "RedisOMMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "RedisOMCore",
            ]
        ),
        .target(
            name: "RedisOMCore"
        ),
        .target(
            name: "RedisOM",
            dependencies: [
                "RedisOMCore",
                "RedisOMMacros",
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "RedisOMTests",
            dependencies: [
                .target(name: "RedisOM"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
        ),
        .testTarget(
            name: "RedisOMMacrosTests",
            dependencies: [
                .target(name: "RedisOMMacros"),
                "RedisOMCore",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
