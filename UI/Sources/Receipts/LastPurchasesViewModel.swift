//
//  LastPurchasesViewModel.swift
//  
//
//  Created by Uwe Tilemann on 31.10.23.
//

import SwiftUI

import SnabbleCore

@Observable @MainActor
public class LastPurchasesViewModel: LoadableObject, @unchecked Sendable {
    typealias Output = [PurchaseProviding]
    
    var projectId: Identifier<Project>? {
        didSet {
            if projectId != oldValue {
                load()
            }
        }
    }
    
    var state: LoadingState<[PurchaseProviding]> = .idle

    public func load() {
        guard let projectId = projectId, let project = Snabble.shared.project(for: projectId) else {
            return state = .empty
        }
        
        state = .idle

        OrderList.load(project) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

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
