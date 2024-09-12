//
//  LoadingViewController.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 22.08.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import UIKit

class LoadingViewController: UIViewController {
    private(set) weak var activityIndicatorView: UIActivityIndicatorView?

    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.color = .primary()
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        self.view = view
    }
}
