// swift-tools-version:5.9

// Copyright © 2019 David Waite
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

// We have two modes of building for now:
// - a modular development mode to create multiple modules. This is done to push
//   for decoupling of code and use of the public api
// - a combined mode that creates a single module. This is what should be
//   checked into GitHub for use

#if true // MODULAR_DEVELOPMENT
let products: [Product] = [
    .library(
            name: "Cyborg",
            targets: ["CyborgBrain", "Cyborg", "CyborgCodable"])
]

let swiftSettings:[SwiftSetting] = [
    .define("MODULAR_DEVELOPMENT"),
    .enableUpcomingFeature("ExistentialAny")
]
let targets: [Target] = [
    .target(
        name: "CyborgBrain",
        dependencies: [.product(name: "NIO", package: "swift-nio"), .product(name: "NIOFoundationCompat", package: "swift-nio")],
        swiftSettings: swiftSettings
    ),
    .target(
        name: "Cyborg",
        dependencies: ["CyborgBrain", .product(name: "BigIntModule", package: "swift-numerics")],
        swiftSettings: swiftSettings
    ),
    .target(
        name: "CyborgCodable",
        dependencies: ["Cyborg"],
        swiftSettings: swiftSettings
    ),
    .testTarget(
        name: "CyborgBrainTests",
        dependencies: ["CyborgBrain", "CwlPreconditionTesting"],
        swiftSettings: swiftSettings
    ),
    .testTarget(
        name: "CyborgTests",
        dependencies: ["Cyborg"],
        swiftSettings: swiftSettings
    ),
    .testTarget(
        name: "CyborgCodableTests",
        dependencies: ["CyborgCodable"],
        swiftSettings: swiftSettings
    )
]
#else
let products: [Product] = [
    .library(
            name: "Cyborg",
            targets: ["Cyborg"])
]

let targets: [Target] = [
    .target(
        name: "Cyborg",
        dependencies: ["BigInt"],
        path: "Sources"
    ),
    .testTarget(
        name: "CyborgTests",
        dependencies: ["Cyborg", "CwlPreconditionTesting"],
        path: "Tests"
    )
]
#endif

let package = Package(
    name: "Cyborg",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
        .watchOS(.v10) // watchOS 6 cannot compile because no XCTest, no SPM support for conditional targets
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git",
                 branch: "master"),
        .package(url: "https://github.com/apple/swift-numerics.git",
                 branch: "biginteger"),
        .package(url: "https://github.com/apple/swift-nio.git",
                 branch: "main")
    ],
    targets: targets,
    swiftLanguageVersions: [.v5]
)
