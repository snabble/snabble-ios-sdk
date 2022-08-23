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

public protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewControllerDidFinish(_ viewController: OnboardingViewController)
}

/// Only use this `ViewController` in a modal presentation
public final class OnboardingViewController: UIHostingController<OnboardingView> {

    public weak var delegate: OnboardingViewControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    public var viewModel: OnboardingViewModel {
        rootView.viewModel
    }

    public init(viewModel: OnboardingViewModel = .default) {
        super.init(rootView: OnboardingView(viewModel: viewModel))
        isModalInPresentation = true
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.$isDone
            .sink { [weak self] in
                if $0 {
                    self?.delegate?.onboardingViewControllerDidFinish(self!)
                }
            }
            .store(in: &cancellables)
    }
}
