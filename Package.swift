// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LazyCaptcha",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "LazyCaptcha",
            targets: ["LazyCaptcha"]
        ),
    ],
    targets: [
        .target(
            name: "LazyCaptcha",
            path: "Sources/LazyCaptcha"
        ),
        .testTarget(
            name: "LazyCaptchaTests",
            dependencies: ["LazyCaptcha"],
            path: "Tests/LazyCaptchaTests"
        ),
    ]
)
