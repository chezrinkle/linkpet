// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinkPet",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LinkPet",
            path: "LinkPet",
            resources: [.copy("Info.plist")]
        )
    ]
)
