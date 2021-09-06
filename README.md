# Snabble 

![License](https://img.shields.io/github/license/mashape/apistatus.svg) 
![Swift 5.0](https://img.shields.io/badge/Swift-5.0-green.svg)
[![Version](https://img.shields.io/cocoapods/v/Snabble.svg)](http://cocoapods.org/pods/Snabble) 
[![Actions Status](https://github.com/snabble/iOS-SDK/workflows/Lint/badge.svg)](https://github.com/snabble/iOS-SDK/actions)
[![Contact](https://img.shields.io/badge/Contact-%40snabble__io-blue)](https://twitter.com/snabble_io)


snabble - the self-scanning and checkout platform.

## Installation

### CocoaPods

Snabble is available through [CocoaPods](https://cocoapods.org), v1.7.0 or later is required.  
To install snabble, add the following line to your `Podfile`:

```
pod 'Snabble'
```

If you only need the core functionality without any UI components, use

```
pod 'Snabble/Core'
```

instead. As with all cocoapods written in Swift, make sure you have `use_frameworks!` in your `Podfile`.

### Optional components

In order to use the `twint` and `postFinanceCard` payment methods, you will also need to include `pod 'Snabble/Datatrans'` in your app's `Podfile`. During the app's initialization phase you will then need to call `DatatransFactory.initialize()` with your app's registered URL scheme to make these methods available. 

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

### Carthage 

[Carthage](https://github.com/Carthage/Carthage) is currently unsupported. 
This is because one of the dependencies we use ([GRDB.swift](https://github.com/groue/GRDB.swift)) does not reliably 
build using Carthage, as documented in their [README](https://github.com/groue/GRDB.swift#carthage). 
If and when this issue gets resolved, you should be able to use the provided `Cartfile`.

### SPM

SPM is currently unsupported, as some of our dependencies do not support it (yet). 
As soon as they do, we will look into SPM support again.

### Manually

Build the example project, as described below, and copy the following frameworks and bundles to your app's target:

* Snabble.framework
* GRDB.framework
* OneTimePassword.framework
* Base32.framework
* TrustKit.framework
* Zip.framework
* Snabble.bundle
* SDCAlertView.framework
* ColorCompatibility.framework
* Capable.framework
* DeviceKit.framework
* Pulley.framework

## Versioning

Snabble follows [semantic versioning](https://semver.org/) rules.
Note that we are currently in initial development, with major version 0. Anything may change at any time.

## Example project

The Example folder contains an extremely simple example for an app. To compile:

````
$ git clone https://github.com/snabble/iOS-SDK
$ cd iOS-SDK/Example
$ pod install
$ open Snabble.xcworkspace
````

To run this sample app, you will need an application identifier and a corresponding secret. [Contact us via e-mail](mailto:&#105;&#110;&#102;&#111;&#064;&#115;&#110;&#097;&#098;&#098;&#108;&#101;&#046;&#105;&#111;) for this information.


## Author

snabble GmbH, Bonn  
[https://snabble.io](https://snabble.io)

## License

snabble is (c) 2021 snabble GmbH, Bonn. The SDK is made available under the [MIT License](https://github.com/snabble/iOS-SDK/blob/main/LICENSE).
