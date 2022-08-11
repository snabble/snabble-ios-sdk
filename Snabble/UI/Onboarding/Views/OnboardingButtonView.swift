//
//  OnboardingButtonView.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 06.08.22.
//

import Foundation
import SwiftUI

struct TintButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(15)
            .background(Appearance.shared.accentColor)
            .foregroundColor(Appearance.shared.buttonTextColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

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
