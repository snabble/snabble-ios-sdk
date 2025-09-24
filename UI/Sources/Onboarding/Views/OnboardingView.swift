//
//  OnboardingView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI

public struct OnboardingView: View {
    @State public var viewModel: OnboardingViewModel
    
    public init(viewModel: OnboardingViewModel) {
        self._viewModel = State(initialValue: viewModel)
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
        @Bindable var viewModel = viewModel
        
        PageViewController(
            pages: viewModel.items.map { OnboardingItemView(item: $0) },
            currentPage: $viewModel.currentPage
        )
        PageControl(
            numberOfPages: viewModel.numberOfPages,
            currentPage: $viewModel.currentPage
        )
        .frame(width: CGFloat(viewModel.numberOfPages * 18))
    }

    @ViewBuilder
    public var footer: some View {
        ButtonControl(
            pages: viewModel.items.map { item in
                OnboardingButtonView(
                    item: item,
                    isLast: viewModel.isLast(item: item),
                    action: {
                        viewModel.next(for: item)
                    })
            },
            currentPage: $viewModel.currentPage
        )
        .animation(.default, value: viewModel.currentPage)
    }

    public var body: some View {
        VStack {
            header
            page
            footer
        }
    }
}

struct ButtonControl: View {
    var pages: [OnboardingButtonView]
    @Binding var currentPage: Int

    var body: some View {
        HStack {
            pages[currentPage]
        }
    }
}
