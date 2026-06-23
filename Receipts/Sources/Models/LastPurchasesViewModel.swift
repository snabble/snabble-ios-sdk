//
//  LastPurchasesViewModel.swift
//  
//
//  Created by Uwe Tilemann on 31.10.23.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents

@Observable
public class LastPurchasesViewModel: LoadableObject, @unchecked Sendable {
    public typealias Output = [any PurchaseProviding]
    
    public var projectId: Identifier<SnabbleCore.Project>? {
        didSet {
            if projectId != oldValue {
                load()
            }
        }
    }
    
    public var state: LoadingState<[any PurchaseProviding]> = .idle

    public func load() {
        guard let projectId = projectId, let project = Snabble.shared.project(for: projectId) else {
            return state = .empty
        }
        
        state = .idle

        OrderList.load(project) { [weak self] result in
            if let self = self {
                do {
                    let providers = try result.get().receipts
                    
                    if providers.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(providers)
                    }
                } catch {
                    self.state = .empty
                }
            }
        }
    }
}
