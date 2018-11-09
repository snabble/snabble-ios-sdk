# Snabble 

![License](https://img.shields.io/github/license/mashape/apistatus.svg) 
![Swift 4.2](https://img.shields.io/badge/Swift-4.2-green.svg)
[![Build](https://api.travis-ci.org/snabble/iOS-SDK.svg?branch=master)](https://travis-ci.org/snabble/iOS-SDK) 
[![Version](https://img.shields.io/cocoapods/v/Snabble.svg)](http://cocoapods.org/pods/Snabble) 

snabble - the self-scanning and checkout platform.

## Installation

Snabble is available through [CocoaPods](http://cocoapods.org). To install it, 
simply add the following line to your Podfile:

```
pod 'Snabble'
```

If you only need the core functionality without any UI components, use

```
pod 'Snabble/Core'
```

As with all cocoapods written in Swift, make sure you have `use_frameworks!` in your Podfile.

## Versioning

snabble follows [semantic versioning](https://semver.org/) rules.
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

## License

snabble is (c) 2018 snabble GmbH, Bonn. The SDK is made available under the MIT License
