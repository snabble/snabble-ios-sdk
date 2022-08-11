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

/// Tinted button used for Onboarding navigation
struct TintButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(15)
            .background(Appearance.shared.accentColor)
            .foregroundColor(Appearance.shared.buttonTextColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// View to render one onboarding item
struct OnboardingButtonView: View {
    var item: OnboardingItem
    var numberOfPages: Int

    @Binding var currentPage: Int

    @ViewBuilder
    var leftButton: some View {
        if let text = item.prevButtonTitle {
            Button(action: {
                if currentPage > 0 {
                    currentPage -= 1
                }
                print("right clicked")
            }) {
                Text(text)
            }
            .buttonStyle(TintButton())
        }
        EmptyView()
    }

    @ViewBuilder
    var rightButton: some View {
        if let text = item.nextButtonTitle {
            Button(action: {
                print("right clicked")
                if currentPage < numberOfPages - 1 {
                    currentPage += 1
                }
            }) {
                Text(text)
            }
            .buttonStyle(TintButton())
        }
        EmptyView()
    }

    @ViewBuilder
    var footer: some View {
        switch item.footerType {
        case .onlyLeft:
            HStack {
                Spacer()
                leftButton
                Spacer()
            }
        case .onlyRight:
            HStack {
                Spacer()
                rightButton
                Spacer()
            }
        case .both:
            HStack {
                leftButton
                Spacer()
                rightButton
            }
        case .none:
            EmptyView()
        }
    }

    var body: some View {
        footer
            .padding([.leading, .trailing], 50)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 20)
    }
}
