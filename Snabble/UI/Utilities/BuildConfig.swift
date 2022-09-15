//
//  BuildConfig.swift
//  Snabble
//
//  Created by Uwe Tilemann on 15.09.22.
//

import Foundation

/// make build configuration parameters available
/// without requiring #if/#endif
enum BuildConfig {
    // is this a release or debug build?
    // this depends on the OTHER_SWIFT_FLAGS project setting, which should include -DRELEASE for release builds and -DDEBUG for debug builds
    #if RELEASE
    static let release = true
    #else
    static let release = false
    #endif

    #if DEBUG
    static let debug = true
    #else
    static let debug = false
    #endif

    #if TEST
    static let test = true
    #else
    static let test = false
    #endif

    #if targetEnvironment(simulator)
    static let simulator = true
    #else
    static let simulator = false
    #endif
}
