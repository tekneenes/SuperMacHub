// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SuperMacHub",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SuperMacHub", targets: ["SuperMacHub"])
    ],
    targets: [
        .executableTarget(
            name: "SuperMacHub",
            path: "Sources/SuperMacHub",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("Vision"),
                .linkedFramework("CoreImage"),
                .linkedFramework("PDFKit"),
                .linkedFramework("EventKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
                .linkedFramework("IOKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("NaturalLanguage"),
                .linkedFramework("UniformTypeIdentifiers")
            ]
        )
    ]
)
