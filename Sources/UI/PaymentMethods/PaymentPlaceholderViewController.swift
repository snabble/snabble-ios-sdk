//
//  PaymentPlaceholderViewController.swift
//
//
//  Created by Uwe Tilemann on 11.04.24.
//

import UIKit
import SnabbleCore
import SwiftUI

public struct PaymentPlaceholderView: View {
    public var body: some View {
        let emptyString = Asset.localizedString(forKey: "Snabble.Payment.EmptyState.message")

        if emptyString != "Snabble.Payment.EmptyState.message" {
            VStack(spacing: 32) {
                if let image: SwiftUI.Image = Asset.image(named: "creditcard", domain: nil) {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72)
                        .foregroundColor(.accentColor)
                }
                
                Text(emptyString)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding([.leading, .trailing], 48)
            }
            .padding()
        }

    }
}

public class PaymentPlaceholderViewController: UIHostingController<PaymentPlaceholderView> {
    public init() {
        super.init(rootView: PaymentPlaceholderView())
    }
        
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.invalidateIntrinsicContentSize()
    }
}
