import PackageDescription

let package = Package(
	name: "WebUntis",
    majorVersion: 1,
    minor: 1,
	dependencies: [
		.Package(url: "https://github.com/google/promises.git", majorVersion: 1, minor: 2),
		.Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 5, minor: 2),
		.Package(url: "https://github.com/realm/realm-cocoa.git", majorVersion: 5, minor: 3),
		.Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", majorVersion: 1, minor: 3),
	]
)
