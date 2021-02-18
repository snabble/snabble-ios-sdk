//
//  SnabbleBundle.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public final class SnabbleBundle: NSObject {
    private static let frameworkBundle = Bundle(for: SnabbleBundle.self)
    static let path = frameworkBundle.path(forResource: "Snabble", ofType: "bundle")!
    public static let main = Bundle(path: path)!
}
