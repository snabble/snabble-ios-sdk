//
//  Order+AsyncReceipt.swift
//
//  Copyright © 2026 snabble. All rights reserved.
//

import Foundation

extension Order {
    /// Async/await wrapper for the callback-based getReceipt(_:completion:).
    public func getReceiptAsync(_ project: Project) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            getReceipt(project) { result in
                continuation.resume(with: result)
            }
        }
    }
}
