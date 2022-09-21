//
//  MethodRegistry.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit

public struct Methods {
    public let viewMethod: (PaymentMethodDetail, AnalyticsDelegate?) -> UIViewController
    public let entryMethod: (RawPaymentMethod, Identifier<Project>, AnalyticsDelegate?) -> UIViewController
    
    public init(viewMethod: @escaping (PaymentMethodDetail, AnalyticsDelegate?) -> UIViewController, entryMethod: @escaping (RawPaymentMethod, Identifier<Project>, AnalyticsDelegate?) -> UIViewController) {
        self.viewMethod = viewMethod
        self.entryMethod = entryMethod
    }
}

public final class MethodRegistry {
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

    public func create(detail: PaymentMethodDetail, analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard let methods = self.methods[detail.rawMethod] else {
            return nil
        }

        return methods.viewMethod(detail, analyticsDelegate)
    }

    public func createEntry(method: RawPaymentMethod, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard let methods = self.methods[method] else {
            return nil
        }

        return methods.entryMethod(method, projectId, analyticsDelegate)
    }
}
