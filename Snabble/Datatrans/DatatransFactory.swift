//
//  DatatransFactory.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

public enum DatatransFactory {
    public static func initialize() {
        let methods = Methods(viewMethod: viewFactory, entryMethod: entryFactory)

        SnabbleAPI.methodRegistry.register(methods: methods, for: .twint)
        SnabbleAPI.methodRegistry.register(methods: methods, for: .postFinanceCard)

        SnabbleAPI.methodRegistry.register(methods: methods, for: .creditCardVisa)
        SnabbleAPI.methodRegistry.register(methods: methods, for: .creditCardMastercard)
        SnabbleAPI.methodRegistry.register(methods: methods, for: .creditCardAmericanExpress)
    }

    private static func viewFactory(_ detail: PaymentMethodDetail, _ showFromCard: Bool, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController {
        return DatatransAliasViewController(detail, showFromCard, analyticsDelegate)

    }

    private static func entryFactory(_ method: RawPaymentMethod, _ projectId: Identifier<Project>, _ showFromCard: Bool, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController {
        return DatatransAliasViewController(method, projectId, showFromCard, analyticsDelegate)
    }
}
