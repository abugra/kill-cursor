// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KillCursor",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "KillCursor",
            targets: ["KillCursor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "KillCursor",
            path: "KillCursor"
        )
    ]
)





