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
    var pages: [OnboardingButtonView]
    @Binding var currentPage: Int

    var body: some View {
        HStack {
            pages[currentPage]
        }
    }
}

public struct OnboardingView: View {
    @ObservedObject public var model: OnboardingModel
    @State private var currentPage = 0

    public init(model: OnboardingModel) {
        self.model = model
    }
    
    @ViewBuilder
    public var header: some View {
        if let image = model.configuration.image {
            image
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 30)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    public var page: some View {
        if model.configuration.hasPageControl == true {
            PageViewController(pages: model.items.map { OnboardingItemView(item: $0) }, currentPage: $currentPage)
            PageControl(numberOfPages: model.items.count, currentPage: $currentPage)
                .frame(width: CGFloat(model.items.count * 18))
        } else {
            ScrollView(.vertical) {
                OnboardingItemView(item: model.items[currentPage])
                .animation(.default, value: currentPage)
                .padding(.top, 70)
            }
        }
    }

    @ViewBuilder
    public var footer: some View {
        ButtonControl(pages: model.items.map { OnboardingButtonView(item: $0, numberOfPages: model.items.count, currentPage: $currentPage) }, currentPage: $currentPage)
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
        OnboardingView(model: OnboardingModel.shared)
    }
}
