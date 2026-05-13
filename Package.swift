// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Bananarator",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Bananarator",
            targets: ["Bananarator"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "Bananarator",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "Bananarator"
        )
    ]
)
