# Snabble

![License](https://img.shields.io/github/license/mashape/apistatus.svg)
![Swift 5.0](https://img.shields.io/badge/Swift-5.0-green.svg)
[![Actions Status](https://github.com/snabble/snabble-ios-sdk/workflows/Lint/badge.svg)](https://github.com/snabble/snabble-ios-sdk/actions)
[![Contact](https://img.shields.io/badge/Contact-%40snabble__io-blue)](https://twitter.com/snabble_io)


snabble - the self-scanning and checkout platform.

## Introduction

Starting with the 0.22.2 release, Snabble officially supports installation via [Swift
Package Manager](https://swift.org/package-manager/).

Prior to version 0.22.2 only Cocoapods is supported

## Requirements

- Requires Xcode 12.5 or above
- See [Package.swift](Package.swift) for supported platform versions.

### Installing from Xcode

Add a package by selecting `File` → `Add Packages…` in Xcode’s menu bar.

Search for the Snabble Apple SDK using the repo's URL:
```console
https://github.com/snabble/snabble-ios-sdk.git
```

Next, set the **Dependency Rule** to be `Up to Next Major Version` and specify `0.22.2` as the lower bound.

Then, select **Add Package**.

Choose the Snabble products that you want installed in your app.


### Alternatively, add Firebase to a `Package.swift` manifest

To integrate via a `Package.swift` manifest instead of Xcode, you can add
Firebase to the dependencies array of your package:

```swift
dependencies:[
  .package(
    name: "Snabble",
    url: "https://github.com/snabble/snabble-ios-sdk.git",
    .upToNextMajor(from: "0.22.2")
  )
]
```

Then, in any target that depends on a Firebase product, add it to the `dependencies`
array of that target:

```swift
.target(
  name: "MyTargetName",
  dependencies: [
    // The product(s) you want (e.g. SnabbleCore).
    .product(name: "SnabbleCore", package: "Snabble"),
  ]
)
```

### Optional components

In order to use the `twint` and `postFinanceCard` payment methods, you will also need to include `'SnabbleDatatrans'` as package in your app. During the app's initialization phase you will then need to call `DatatransFactory.initialize()` with your app's registered URL scheme to make these methods available.

Note that support for these payment methods also requires changes to your app's `Info.plist` as described in Datatrans' SDK [documentation](https://docs.datatrans.ch/docs/mobile-sdk#section-additional-requirements-for-i-os), as well as adding a URL scheme that can be used to pass data back to your app, e.g. by adding

```
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>YOUR_URL_NAME_HERE</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_URL_SCHEME_HERE</string>
    </array>
  </dict>
</array>
```

## Versioning

Snabble follows [semantic versioning](https://semver.org/) rules.
Note that we are currently in initial development, with major version 0. Anything may change at any time.

## Documentation

https://docs.snabble.io/docs/ios/

## Example project

The Example folder contains an extremely simple example for an app. To compile:

````
$ git clone https://github.com/snabble/snabble-ios-sdk
$ cd snabble-ios-sdk/Example
$ open SnabbleSampleApp.xcworkspace
````

To run this sample app, you will need an application identifier and a corresponding secret. [Contact us via e-mail](mailto:&#105;&#110;&#102;&#111;&#064;&#115;&#110;&#097;&#098;&#098;&#108;&#101;&#046;&#105;&#111;) for this information.


## Author

snabble GmbH, Bonn
[https://snabble.io](https://snabble.io)

## License

snabble is (c) 2021 snabble GmbH, Bonn. The SDK is made available under the [MIT License](https://github.com/snabble/iOS-SDK/blob/main/LICENSE).
