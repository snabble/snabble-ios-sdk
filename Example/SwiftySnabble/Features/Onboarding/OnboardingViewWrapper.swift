//
//  OnboardingViewWrapper.swift
//  Snabble Sample App
//
//  Created by Uwe Tilemann on 02.03.26.
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleAssetProviding
import SnabbleOnboarding

struct OnboardingViewWrapper: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var viewModel: OnboardingViewModel
    
    init() {
        viewModel = loadJSON("Onboarding")
    }
    
    var body: some View {
        OnboardingView(viewModel: viewModel)
            .padding(.vertical)
            .onChange(of: viewModel.isDone) {
                if viewModel.isDone {
                    dismiss()
                }
            }
    }
}
