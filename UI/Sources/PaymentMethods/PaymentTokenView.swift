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
                    TelecashView(
                        paymentMethodDetail: $paymentMethodDetail,
                        user: user,
                        didCancel: didComplete,
                        rawPaymentMethod: rawPaymentMethod,
                        projectId: projectId)
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
}
