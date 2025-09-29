//
//  MethodRegistry.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias OSViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
public typealias OSViewController = NSViewController
#else
public typealias OSViewController = AnyObject
#endif

public struct Methods {
    public let viewMethod: (PaymentMethodDetail, AnalyticsDelegate?) -> OSViewController
    public let entryMethod: (RawPaymentMethod, Identifier<Project>, AnalyticsDelegate?) -> OSViewController
    
    public init(viewMethod: @escaping (PaymentMethodDetail, AnalyticsDelegate?) -> OSViewController, entryMethod: @escaping (RawPaymentMethod, Identifier<Project>, AnalyticsDelegate?) -> OSViewController) {
        self.viewMethod = viewMethod
        self.entryMethod = entryMethod
    }
}

public final class MethodRegistry: @unchecked Sendable {
    private var methods = [RawPaymentMethod: Methods]()

    public func isMethodAvailable(_ method: RawPaymentMethod) -> Bool {
        if method.needsPlugin {
            return self.methods[method] != nil
        }
        return true
    }

    public func register(methods: Methods, for method: RawPaymentMethod) {
        self.methods[method] = methods
    }

    public func deregister(method: RawPaymentMethod) {
        self.methods[method] = nil
    }

    public func create(detail: PaymentMethodDetail, analyticsDelegate: AnalyticsDelegate?) -> OSViewController? {
        guard let methods = self.methods[detail.rawMethod] else {
            return nil
        }

        return methods.viewMethod(detail, analyticsDelegate)
    }

    public func createEntry(method: RawPaymentMethod, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) -> OSViewController? {
        guard let methods = self.methods[method] else {
            return nil
        }

        return methods.entryMethod(method, projectId, analyticsDelegate)
    }
}
