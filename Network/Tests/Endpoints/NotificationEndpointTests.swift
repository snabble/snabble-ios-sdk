//
//  NotificationEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2024-04-05.
//

import Foundation
import XCTest
@testable import SnabbleNetwork

final class NotificationEndpointTests: XCTestCase {

    var configuration: Configuration = .init(appId: "1", appSecret: "ABCDEFGHIJKLMNOP", domain: .production)

    func testSubscribe() throws {
        let endpoint = Endpoints.Notification.subscribe(fcmToken: "1234-567-890", appId: "555")
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/notifications/subscribe/me")
        let urlRequest = try endpoint.applying(domain: .production).urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/notifications/subscribe/me")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        let data = try! JSONSerialization.data(withJSONObject: [
            "appID": "555",
            "token": "1234-567-890"
        ])
        XCTAssertEqual(urlRequest.httpBody?.count, data.count)
    }

    func testUnsubscribe() throws {
        let endpoint = Endpoints.Notification.unsubscribe(appId: "555")
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/notifications/unsubscribe/me")
        let urlRequest = try endpoint.applying(domain: .production).urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/notifications/unsubscribe/me")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        let data = try! JSONSerialization.data(withJSONObject: [
            "appID": "555"
        ])
        XCTAssertEqual(urlRequest.httpBody?.count, data.count)
    }
}
