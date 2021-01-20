//
//  ObjectAssociation.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 20.01.21.
//

import Foundation
import ObjectiveC

final class ObjectAssociation<T: AnyObject> {

    private let policy: objc_AssociationPolicy

    /// - Parameter policy: An association policy that will be used when linking objects.
    init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }

    /// Accesses associated object.
    /// - Parameter index: An object whose associated object is to be accessed.
    subscript(index: AnyObject) -> T? {
        get {
            objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as? T? ?? nil
        }
        set {
            objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy)
        }
    }
}
