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
    var leftButtonTitle: String? { get }
    var rightButtonTitle: String? { get }
}

private enum DoubleButtonType {
    case none
    case left
    case right
    case both
}

private extension DoubleButtonViewProvider {
    var type: DoubleButtonType {
        if leftButtonTitle == nil, rightButtonTitle == nil {
            return .none
        } else if leftButtonTitle != nil, rightButtonTitle == nil {
            return .left
        } else if rightButtonTitle != nil, leftButtonTitle == nil {
            return .right
        } else {
            return .both
        }
    }
}

/// View to render one onboarding item
struct DoubleButtonView: View {
    var provider: DoubleButtonViewProvider

    var left: () -> Void
    var right: () -> Void

    @ViewBuilder
    var leftButton: some View {
        if let text = provider.leftButtonTitle {
            Button(action: {
                left()
            }) {
                Text(keyed: text)
            }
            .buttonStyle(AccentButtonStyle())
        }
        EmptyView()
    }

    @ViewBuilder
    var rightButton: some View {
        if let text = provider.rightButtonTitle {
            Button(action: {
                right()
            }) {
                Text(keyed: text)
            }
            .buttonStyle(AccentButtonStyle())
        }
        EmptyView()
    }

    @ViewBuilder
    var container: some View {
        switch provider.type {
        case .left:
            HStack {
                Spacer()
                leftButton
                Spacer()
            }
        case .right:
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
        container
            .padding([.leading, .trailing], 50)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 20)
    }
}

extension OnboardingItem: DoubleButtonViewProvider {
    var leftButtonTitle: String? {
        prevButtonTitle
    }

    var rightButtonTitle: String? {
        nextButtonTitle
    }
}
