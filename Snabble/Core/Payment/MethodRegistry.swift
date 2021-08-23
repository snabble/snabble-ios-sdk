//
//  MethodRegistry.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

struct Methods {
    let viewMethod: (PaymentMethodDetail, AnalyticsDelegate?) -> UIViewController
    let entryMethod: (RawPaymentMethod, Identifier<Project>, AnalyticsDelegate?) -> UIViewController
}

final class MethodRegistry {
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

    func create(detail: PaymentMethodDetail, analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard let methods = self.methods[detail.rawMethod] else {
            return nil
        }

        return methods.viewMethod(detail, analyticsDelegate)
    }

    func createEntry(method: RawPaymentMethod, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard let methods = self.methods[method] else {
            return nil
        }

        return methods.entryMethod(method, projectId, analyticsDelegate)
    }
}
