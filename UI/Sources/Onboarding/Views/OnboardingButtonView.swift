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
import SnabbleComponents

/// View to render one onboarding item
struct OnboardingButtonView: View {
    var item: OnboardingItem

    var isLast: Bool
    var action: () -> Void

    @ViewBuilder
    var button: some View {
        Button(action: {
            action()
        }) {
            if let title = item.customButtonTitle {
                Text(LocalizedStringKey(title))
            } else {
                Text(keyed: isLast ? "Snabble.Onboarding.done" : "Snabble.Onboarding.next")
            }
        }
        .buttonStyle(ProjectPrimaryButtonStyle())
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
