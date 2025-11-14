// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIHealthyMealPlannerApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AIHealthyMealPlannerApp",
            targets: ["AIHealthyMealPlannerApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "AIHealthyMealPlannerApp",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/AIHealthyMealPlannerApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AIHealthyMealPlannerAppTests",
            dependencies: ["AIHealthyMealPlannerApp"],
            path: "Tests/AIHealthyMealPlannerAppTests"
        )
    ]
)
