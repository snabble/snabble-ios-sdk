//
//  DatatransFactory.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

public enum DatatransFactory {
    private(set) static var appCallbackScheme: String?

    public static func initialize(appCallbackScheme: String) {
        Self.appCallbackScheme = appCallbackScheme

        let methods = Methods(viewMethod: viewFactory, entryMethod: entryFactory)

        Snabble.methodRegistry.register(methods: methods, for: .twint)
        Snabble.methodRegistry.register(methods: methods, for: .postFinanceCard)

        Snabble.methodRegistry.register(methods: methods, for: .creditCardVisa)
        Snabble.methodRegistry.register(methods: methods, for: .creditCardMastercard)
        Snabble.methodRegistry.register(methods: methods, for: .creditCardAmericanExpress)
    }

    private static func viewFactory(_ detail: PaymentMethodDetail, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController {
        return DatatransAliasViewController(detail, analyticsDelegate)
    }

    private static func entryFactory(_ method: RawPaymentMethod, _ projectId: Identifier<Project>, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController {
        return DatatransAliasViewController(method, projectId, analyticsDelegate)
    }
}
