//
//  OnboardingViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 22.08.22.
//

import Foundation
import UIKit
import SwiftUI

/// Only use this `ViewController` in a modal presentation
public final class OnboardingViewController: UIHostingController<OnboardingView> {

    public var viewModel: OnboardingViewModel {
        rootView.model
    }

    public init(viewModel: OnboardingViewModel = .default) {
        super.init(rootView: OnboardingView(model: viewModel))
        isModalInPresentation = true
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
