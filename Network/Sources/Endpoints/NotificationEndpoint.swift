//
//  NotificationEndpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2024-04-05.
//

import Foundation

extension Endpoints {
    public enum Notification {
        public static func subscribe(fcmToken: String, appId: String) -> Endpoint<Void> {
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "token": fcmToken,
                "appID": appId
            ])
            return .init(
                path: "/notifications/subscribe/me",
                method: .post(data),
                parse: { _ in
                    return ()
                }
            )
        }
        
        public static func unsubscribe(appId: String) -> Endpoint<Void> {
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "appID": appId
            ])
            return .init(
                path: "/notifications/unsubscribe/me",
                method: .post(data),
                parse: { _ in
                    return ()
                }
            )
        }
    }
}
