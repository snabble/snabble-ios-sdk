//
//  PaymentTokenView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-10-28.
//

import SwiftUI
import SnabbleCore
import SnabbleUser
import SnabbleAssetProviding

public struct PaymentTokenView: View {
    @State var path: NavigationPath = NavigationPath()
    
    var didComplete: (() -> Void)?
    
    let rawPaymentMethod: RawPaymentMethod
    let projectId: Identifier<Project>
    
    public init(paymentMethodDetail: Binding<PaymentMethodDetail?>, rawPaymentMethod: RawPaymentMethod, projectId: Identifier<Project>, didComplete: (() -> Void)?) {
        self._paymentMethodDetail = paymentMethodDetail
        self.rawPaymentMethod = rawPaymentMethod
        self.projectId = projectId
        self.didComplete = didComplete
    }
    
    @State var user: SnabbleUser.User?
    @Binding var paymentMethodDetail: PaymentMethodDetail?
    
    public var body: some View {
        NavigationStack(path: $path) {
            SnabbleUser.UserView(user: $user)
                .navigationDestination(item: $user, destination: { user in
                    switch provider(forProjectId: projectId, withRawPaymentMethod: rawPaymentMethod) {
                    case .none:
                        Text("\(rawPaymentMethod.displayName) is not supported")
                    case .telecash:
                        TelecashView(
                            paymentMethodDetail: $paymentMethodDetail,
                            user: user,
                            didComplete: didComplete,
                            rawPaymentMethod: rawPaymentMethod,
                            projectId: projectId)
                    case .payone:
                        PayoneView(
                            paymentMethodDetail: $paymentMethodDetail,
                            user: user,
                            didComplete: didComplete,
                            rawPaymentMethod: rawPaymentMethod,
                            projectId: projectId)
                    }
                })
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(Asset.localizedString(forKey: "Snabble.cancel")) {
                            didComplete?()
                        }
                    }
                }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func provider(forProjectId projectId: Identifier<Project>, withRawPaymentMethod method: RawPaymentMethod) -> Provider {
        guard
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == method }) else {
                return .none
            }
        
        if descriptor.acceptedOriginTypes?.contains(.ipgHostedDataID) == true {
            return .telecash
        }
        if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
            return .payone
        }
        return .none
    }
    
    private enum Provider {
        case none
        case telecash
        case payone
    }
}
