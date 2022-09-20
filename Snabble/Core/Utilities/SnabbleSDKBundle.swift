//
//  SnabbleSDKBundle.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public final class SnabbleSDKBundle: NSObject {
    static let resourceBundle: Bundle = {
        let myBundle = Bundle(for: SnabbleSDKBundle.self)

        guard let resourceBundleURL = myBundle.url(forResource: "SnabbleSDK", withExtension: "bundle") else {
            fatalError("SnabbleSDK.bundle not found!")

        }

        guard let resourceBundle = Bundle(url: resourceBundleURL) else {
            fatalError("Cannot access SnabbleSDKResources.bundle!")
        }
        return resourceBundle
    }()
}
