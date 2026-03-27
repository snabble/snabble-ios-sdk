//
//  BuildConfig.swift
//  Snabble
//
//  Created by Uwe Tilemann on 15.09.22.
//

import Foundation

/// make build configuration parameters available
/// without requiring #if/#endif
public enum BuildConfig {
    // is this a release or debug build?
    // this depends on the OTHER_SWIFT_FLAGS project setting, which should include -DRELEASE for release builds and -DDEBUG for debug builds
    #if RELEASE
    public static let release = true
    #else
    public static let release = false
    #endif

    #if DEBUG
    public static let debug = true
    #else
    public static let debug = false
    #endif

    #if TEST
    public static let test = true
    #else
    public static let test = false
    #endif

    #if targetEnvironment(simulator)
    public static let simulator = true
    #else
    public static let simulator = false
    #endif
}
