//
//  ScannerDelegate.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import SnabbleCore

public struct ScanMessage {
    public let text: String
    public let attributedString: NSAttributedString?
    public let imageUrl: String?
    // when to dismiss the message
    // nil - time is based on message length
    // 0 - no autodismiss
    // other values - dismiss after X seconds
    public let dismissTime: TimeInterval?

    public init(_ text: String, _ imageUrl: String? = nil, _ dismissTime: TimeInterval? = nil) {
        self.text = text
        self.imageUrl = imageUrl
        self.attributedString = nil
        self.dismissTime = dismissTime
    }

    public init(_ text: String, _ attributedString: NSAttributedString, _ imageUrl: String? = nil, _ dismissTime: TimeInterval? = nil) {
        self.text = text
        self.imageUrl = imageUrl
        self.attributedString = attributedString
        self.dismissTime = dismissTime
    }
}

@MainActor
public protocol ScannerDelegate: AnalyticsDelegate {
    /// check if we need to display a special message when scanning this product, like
    /// "don't forget to grab the other X packages"
    func scanMessage(for project: Project, _ shop: Shop, _ product: Product) -> ScanMessage?
}
