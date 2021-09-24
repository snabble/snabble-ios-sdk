//
//  UIViewController+Overlay.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit
import AutoLayout_Helper

extension UIViewController {
    // MARK: - UIView

    private static let backgroundViewAssociation = ObjectAssociation<UIView>(policy: .OBJC_ASSOCIATION_ASSIGN)
    private static let overlayViewAssociation = ObjectAssociation<UIView>(policy: .OBJC_ASSOCIATION_ASSIGN)

    private var backgroundView: UIView? {
        get {
            UIViewController.backgroundViewAssociation[self]
        }
        set {
            UIViewController.backgroundViewAssociation[self] = newValue
        }
    }

    private var overlayView: UIView? {
        get {
            UIViewController.overlayViewAssociation[self]
        }
        set {
            UIViewController.overlayViewAssociation[self] = newValue
        }
    }

    private static let bottomConstraintIdentifier = "bottomOverlayConstraint"

    public func showOverlay(with overlayView: UIView) {
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.backgroundColor = UIColor.label.withAlphaComponent(0.5)
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
    }

    public func dismissOverlay() {
        view.layoutIfNeeded()

        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.view.constraints.first(with: Self.bottomConstraintIdentifier)?.isActive = false
                self?.view.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                self?.backgroundView?.removeFromSuperview()
                self?.overlayView?.removeFromSuperview()
            }
        )
    }

    // MARK: - Window

    private static let windowAssociation = ObjectAssociation<UIWindow>()

    private var overlayWindow: UIWindow? {
        get {
            UIViewController.windowAssociation[self]
        }
        set {
            UIViewController.windowAssociation[self] = newValue
        }
    }

    func showWindowOverlay(with overlayView: UIView) {
        let viewController = UIViewController()

        if #available(iOS 13.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            overlayWindow = UIWindow(windowScene: windowScene!)
        } else {
            overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        }

        overlayWindow?.backgroundColor = UIColor.label.withAlphaComponent(0.5)
        overlayWindow?.rootViewController = viewController
        overlayWindow?.windowLevel = .normal
        overlayWindow?.makeKeyAndVisible()

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalToSystemSpacingAfter: viewController.view.leadingAnchor, multiplier: 2),
            viewController.view.trailingAnchor.constraint(equalToSystemSpacingAfter: overlayView.trailingAnchor, multiplier: 2),

            overlayView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            overlayView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),

            overlayView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: viewController.view.topAnchor, multiplier: 2),
            viewController.view.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: overlayView.bottomAnchor, multiplier: 2)
        ])
    }
}
