// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "socket.io-vapor",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "SocketIO", targets: ["SocketIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/barnanemeth/engine.io-vapor", exact: "0.0.7"),
    ],
    targets: [
        .target(
            name: "SocketIO",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "EngineIO", package: "engine.io-vapor")
            ],
            path: "Sources"
        )
    ]
)
