//
//  UIViewController+Overlay.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit
import SnabbleCore

extension UIViewController {
    // MARK: - UIView

    private static let backgroundViewAssociation = ObjectAssociation<UIView>(policy: .OBJC_ASSOCIATION_ASSIGN)
    private static let overlayViewAssociation = ObjectAssociation<UIView>(policy: .OBJC_ASSOCIATION_ASSIGN)
    private static let overlayViewControllerAssociation = ObjectAssociation<UIViewController>(policy: .OBJC_ASSOCIATION_ASSIGN)

    private var backgroundView: UIView? {
        get {
            UIViewController.backgroundViewAssociation[self] ?? nil
        }
        set {
            UIViewController.backgroundViewAssociation[self] = newValue
        }
    }

    private var overlayView: UIView? {
        get {
            UIViewController.overlayViewAssociation[self] ?? nil
        }
        set {
            UIViewController.overlayViewAssociation[self] = newValue
        }
    }

    private var overlayViewController: UIViewController? {
        get {
            UIViewController.overlayViewControllerAssociation[self] ?? nil
        }
        set {
            UIViewController.overlayViewControllerAssociation[self] = newValue
        }
    }

    private static let bottomConstraintIdentifier = "bottomOverlayConstraint"

    public func showOverlay(with overlayViewController: UIViewController) {
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.backgroundColor = .label.withAlphaComponent(0.5)
        view.addSubview(backgroundView)
        self.backgroundView = backgroundView

        let overlayView = overlayViewController.view!
        addChild(overlayViewController)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        self.overlayView = overlayView

        let layoutGuide: UILayoutGuide = (self as? UINavigationController)?.topViewController?.view.safeAreaLayoutGuide ?? view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 2),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: overlayView.trailingAnchor, multiplier: 2),

            overlayView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.topAnchor, multiplier: 2),
            overlayView.topAnchor.constraint(equalTo: layoutGuide.bottomAnchor).usingPriority(.defaultLow - 1)
        ])

        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) { [self] in
            NSLayoutConstraint.activate([
                layoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: overlayView.bottomAnchor, multiplier: 2)
                    .usingIdentifier(Self.bottomConstraintIdentifier)
            ])
            view.layoutIfNeeded()
        }
        overlayViewController.didMove(toParent: self)
        self.overlayViewController = overlayViewController
    }

    public func showOverlay(with overlayView: UIView) {
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.backgroundColor = .label.withAlphaComponent(0.5)
        view.addSubview(backgroundView)
        self.backgroundView = backgroundView

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        self.overlayView = overlayView

        let layoutGuide: UILayoutGuide = (self as? UINavigationController)?.topViewController?.view.safeAreaLayoutGuide ?? view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 2),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: overlayView.trailingAnchor, multiplier: 2),

            overlayView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.topAnchor, multiplier: 2),
            overlayView.topAnchor.constraint(equalTo: layoutGuide.bottomAnchor).usingPriority(.defaultLow - 1)
        ])

        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) { [self] in
            NSLayoutConstraint.activate([
                layoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: overlayView.bottomAnchor, multiplier: 2)
                    .usingIdentifier(Self.bottomConstraintIdentifier)
            ])
            view.layoutIfNeeded()
        }
        self.overlayViewController = nil
    }

    public func dismissOverlay(animated: Bool = true) {
        if let viewController = overlayViewController {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
            backgroundView?.removeFromSuperview()
        } else {
            view.layoutIfNeeded()
            UIView.animate(
                withDuration: animated ? 0.3 : 0.0,
                animations: { [weak self] in
                    self?.view.constraints.first(with: Self.bottomConstraintIdentifier)?.isActive = false
                    self?.view.layoutIfNeeded()
                },
                completion: { [weak self] _ in
                    self?.backgroundView?.removeFromSuperview()
                    self?.overlayView?.removeFromSuperview()
                    self?.overlayView = nil
                    self?.backgroundView = nil
                }
            )
        }
        self.overlayViewController = nil
    }
}
