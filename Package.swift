// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AmbientSync",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "AmbientSync", targets: ["AmbientSync"]),
    ],
    targets: [
        .executableTarget(
            name: "AmbientSync",
            resources: [
                .copy("Resources/HiDPIOverrides/Samsung_4C2D_76AB_reference.plist")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
            ]
        ),
        .testTarget(
            name: "AmbientSyncTests",
            dependencies: ["AmbientSync"]
        )
    ]
)
