//
//  OnboardingViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 22.08.22.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import Observation

/// Methods for managing completion of onboarding
public protocol OnboardingViewControllerDelegate: AnyObject {

    /// Tells the delegate that the onboarding is finished
    /// - Parameter viewController: A viewController informing the delegate about the completion
    func onboardingViewControllerDidFinish(_ viewController: OnboardingViewController)
}

/// Only use this `ViewController` in a modal presentation
/// - Important: `isModalInPresentation` is default set to `true`
public final class OnboardingViewController: UIHostingController<OnboardingView> {

    /// The object that acts as the delegate of the onboarding view controller.
    public weak var delegate: OnboardingViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    /// The used viewModel to show onboarding details
    public let viewModel: OnboardingViewModel

    /// Creates and returns an onboarding view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(rootView: OnboardingView().environment(viewModel))
        isModalInPresentation = true
        modalPresentationStyle = .overFullScreen
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        withObservationTracking {
            _ = viewModel.isDone
        } onChange: { [weak self] in
            Task { @MainActor in
                if self?.viewModel.isDone == true {
                    self?.delegate?.onboardingViewControllerDidFinish(self!)
                }
            }
        }
    }
}
