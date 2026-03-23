//
//  MessageDelegate.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

@MainActor
public protocol MessageDelegate: AnyObject {
    func showInfoMessage(_ message: String)
    func showWarningMessage(_ message: String)
}
