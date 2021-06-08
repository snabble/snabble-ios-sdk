//
//  SnabbleDTBundle.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

public final class SnabbleDTBundle: NSObject {
    private static let frameworkBundle = Bundle(for: SnabbleDTBundle.self)
    static let path = frameworkBundle.path(forResource: "SnabbleDT", ofType: "bundle")!
    public static let main = Bundle(path: path)!
}
