//
//  OnboardingButtonView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SwiftUI

protocol DoubleButtonViewProvider {
    var buttonTitle: String { get }
}

/// View to render one onboarding item
struct DoubleButtonView: View {
    var provider: DoubleButtonViewProvider

    var action: () -> Void

    @ViewBuilder
    var button: some View {
        Button(action: {
            action()
        }) {
            Text(key: provider.buttonTitle)
        }
        .buttonStyle(AccentButtonStyle())
    }

    @ViewBuilder
    var container: some View {
        HStack {
            Spacer()
            button
            Spacer()
        }
    }

    var body: some View {
        container
            .padding([.leading, .trailing], 50)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 20)
    }
}

extension OnboardingItem: DoubleButtonViewProvider {
    var buttonTitle: String {
        customButtonTitle ?? "Snabble.Onboarding.next"
    }
}
