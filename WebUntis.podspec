
Pod::Spec.new do |spec|
    spec.name = "WebUntis"
    spec.version = "1.1.0"
    spec.summary = "WebUntis Swift framework."
    spec.homepage = "https://noim.io"
    spec.license = { type: 'MIT', file: 'LICENSE' }
    spec.authors = { "Nils Bergmann" => 'nilsbergmann@noim.io' }
    spec.social_media_url = "http://twitter.com/EpicNilo"


    spec.ios.deployment_target  = '11.0'
    spec.watchos.deployment_target = '4.0'
    spec.swift_version = '5'

    spec.requires_arc = true
    spec.source = { git: "https://github.com/TheNoim/WebUntis-Swift.git", tag: "v#{spec.version}", submodules: true }
    spec.source_files = "Sources/**/*.{h,swift}"

    spec.dependency "PromisesSwift", "~> 1.2.10"
    spec.dependency "Alamofire", "~> 5.2.2"
    spec.dependency "RealmSwift", "~> 5.4.0"
    spec.dependency "CryptoSwift", "~> 1.3.1"
end
