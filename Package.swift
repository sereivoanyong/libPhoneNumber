// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "libPhoneNumber",
    platforms: [
        .iOS(.v9), .macOS(.v10_10), .tvOS(.v9), .watchOS(.v2)
    ],
    products: [
        .library(name: "libPhoneNumber", targets: ["libPhoneNumber"]),
        .library(name: "libPhoneNumber-Static", type: .static, targets: ["libPhoneNumber"]),
        .library(name: "libPhoneNumber-Dynamic", type: .dynamic, targets: ["libPhoneNumber"])
    ],
    targets: [
        .target(name: "libPhoneNumber",
                path: "libPhoneNumber",
                exclude: ["Resources/Original", "Resources/README.md", "Resources/update.sh"],
                resources: [.process("Resources/PhoneNumberMetadata.json")]),
        .testTarget(name: "libPhoneNumberTests",
                    dependencies: ["libPhoneNumber"],
                    path: "libPhoneNumberTests")
    ]
)
