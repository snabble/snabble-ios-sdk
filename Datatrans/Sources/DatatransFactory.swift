//
//  DatatransFactory.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import SnabbleCore
import UIKit

public enum DatatransFactory {
    private(set) nonisolated(unsafe) static var appCallbackScheme: String?

    public static func initialize(appCallbackScheme: String) {
        Self.appCallbackScheme = appCallbackScheme

        let methods = Methods(
            viewMethod: { detail, analyticsDelegate in
                nonisolated(unsafe) let capturedDetail = detail
                nonisolated(unsafe) let capturedAnalyticsDelegate = analyticsDelegate
                return MainActor.assumeIsolated {
                    DatatransAliasViewController(capturedDetail, capturedAnalyticsDelegate)
                }
            },
            entryMethod: { method, projectId, analyticsDelegate in
                let capturedMethod = method
                let capturedProjectId = projectId
                nonisolated(unsafe) let capturedAnalyticsDelegate = analyticsDelegate
                return MainActor.assumeIsolated {
                    DatatransAliasViewController(capturedMethod, capturedProjectId, capturedAnalyticsDelegate)
                }
            }
        )

        Snabble.methodRegistry.register(methods: methods, for: .twint)
        Snabble.methodRegistry.register(methods: methods, for: .postFinanceCard)

        Snabble.methodRegistry.register(methods: methods, for: .creditCardVisa)
        Snabble.methodRegistry.register(methods: methods, for: .creditCardMastercard)
        Snabble.methodRegistry.register(methods: methods, for: .creditCardAmericanExpress)
    }
}
