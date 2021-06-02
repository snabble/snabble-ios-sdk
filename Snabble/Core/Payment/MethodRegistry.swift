//
//  MethodRegistry.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

struct Methods {
    let viewMethod: (PaymentMethodDetail, Bool, AnalyticsDelegate?) -> UIViewController
    let entryMethod: (RawPaymentMethod, Identifier<Project>, Bool, AnalyticsDelegate?) -> UIViewController
}

class MethodRegistry {
    private var methods = [RawPaymentMethod: Methods]()

    func isMethodAvailable(_ method: RawPaymentMethod) -> Bool {
        if method.needsPlugin {
            return self.methods[method] != nil
        }
        return true
    }

    func register(methods: Methods, for method: RawPaymentMethod) {
        self.methods[method] = methods
    }

    func deregister(method: RawPaymentMethod) {
        self.methods[method] = nil
    }

    func create(detail: PaymentMethodDetail, showFromCart: Bool, analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard let methods = self.methods[detail.rawMethod] else {
            return nil
        }

        return methods.viewMethod(detail, showFromCart, analyticsDelegate)
    }

    func createEntry(method: RawPaymentMethod, _ projectId: Identifier<Project>, _ showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard let methods = self.methods[method] else {
            return nil
        }

        return methods.entryMethod(method, projectId, showFromCart, analyticsDelegate)
    }
}
