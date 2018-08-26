import PackageDescription

let package = Package(
	name: "WebUntis",
	dependencies: [
		.Package(url: "https://github.com/google/promises.git", majorVersion: 1, minor: 2),
		.Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4, minor: 7),
		.Package(url: "https://github.com/realm/realm-cocoa.git", majorVersion: 3, minor: 7),
		.Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", majorVersion: 0, minor: 11),
	]
)
