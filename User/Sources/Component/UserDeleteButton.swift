//
//  UserDeleteButton.swift
//  
//
//  Created by Uwe Tilemann on 08.06.24.
//

import SwiftUI

import SnabbleNetwork
import SnabbleAssetProviding

public struct UserDeleteButton: View {
    @SwiftUI.Environment(NetworkManager.self) var networkManager
    
    @State private var showDeleteConfirmation = false
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    let onCompletion: () -> Void
    
    public init(onCompletion: @escaping () -> Void) {
        self.onCompletion = onCompletion
    }
    
    public var body: some View {
        VStack {
            SecondaryButtonView(title: Asset.localizedString(forKey: "Snabble.Account.Delete.buttonLabel"),
                                disabled: Binding(get: { isLoading }, set: { _ in }),
                                onAction: {
                showDeleteConfirmation = true
            })
            if isLoading {
                ProgressView()
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(title: Text(keyed: "Snabble.Account.Delete.Dialog.title"),
                  message: Text(keyed: "Snabble.Account.Delete.Dialog.message"),
                  primaryButton: .destructive(Text(keyed: "Snabble.Account.Delete.Dialog.continue")) {
                delete()
            },
                  secondaryButton: .cancel())
        }
    }

    private func delete() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                try await networkManager.publisher(for: Endpoints.User.erase())
                onCompletion()
            } catch {
                errorMessage = Asset.localizedString(forKey: "Snabble.Account.Delete.error")
            }
            isLoading = false
        }
    }
}
