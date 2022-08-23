//
//  OnboardingView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI

struct ButtonControl: View {
    var pages: [DoubleButtonView]
    @Binding var currentPage: Int

    var body: some View {
        HStack {
            pages[currentPage]
        }
    }
}

public struct OnboardingView: View {
    @ObservedObject public var viewModel: OnboardingViewModel
    @State var currentPage: Int = 0

    public init(viewModel: OnboardingViewModel = .default) {
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    public var header: some View {
        if let image = viewModel.configuration.image {
            image
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 30)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.top, 10)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    public var page: some View {
        if viewModel.configuration.hasPageControl {
            PageViewController(
                pages: viewModel.items.map { OnboardingItemView(item: $0) },
                currentPage: $currentPage
            )
            PageControl(
                numberOfPages: viewModel.items.count,
                currentPage: $currentPage
            )
                .frame(width: CGFloat(viewModel.items.count * 18))
        } else {
            ScrollView(.vertical) {
                OnboardingItemView(item: viewModel.items[currentPage])
                    .animation(.default, value: currentPage)
                    .padding(.top, 70)
            }
        }
    }

    @ViewBuilder
    public var footer: some View {
        ButtonControl(
            pages: viewModel.items.map {
                DoubleButtonView(
                    provider: $0,
                    left: {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                    },
                    right: {
                        if currentPage < viewModel.numberOfPages - 1 {
                            currentPage += 1
                        } else if currentPage == viewModel.numberOfPages - 1 {
                            viewModel.isDone = true
                        }
                    })
            },
            currentPage: $currentPage
        )
        .animation(.default, value: currentPage)
    }

    public var body: some View {
        VStack {
            header
            page
            footer
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: OnboardingViewModel.default)
    }
}
