//
//  OnboardingViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 22.08.22.
//

import Foundation
import UIKit
import SwiftUI

public protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewControllerShouldBeDismissed(_ onboardingViewController: OnboardingViewController)
}

public final class OnboardingViewController: UIHostingController<OnboardingView> {

    public weak var delegate: OnboardingViewControllerDelegate?

    public var viewModel: OnboardingViewModel {
        rootView.model
    }

    public init(viewModel: OnboardingViewModel = .default) {
        super.init(rootView: OnboardingView(model: viewModel))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
