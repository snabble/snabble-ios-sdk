//
//  AlertView.swift
//  
//
//  Created by Uwe Tilemann on 14.11.22.
//

import UIKit

@MainActor
class AlertView: @unchecked Sendable {
    private var window: UIWindow?
    public var alertController: UIAlertController?
    private var presentingViewController: ClearViewController

    private var firstWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first
    }

    init(title: String?, message: String?) {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.presentingViewController = ClearViewController()
        self.window?.rootViewController = self.presentingViewController
        self.window?.windowLevel = UIWindow.Level.alert + 1
        
        self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    
    func show() {
        if let alertController = alertController {
            DispatchQueue.main.async {
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func addAction(_ action: UIAlertAction) {
        if let alertController = alertController {
            alertController.addAction(action)
        }
    }
    
    func addCancelButton(string: String) {
        if let alertController = alertController {
            alertController.addAction(UIAlertAction(title: string, style: .cancel, handler: nil))
        }
    }

    func dismiss(animated: Bool) {
        DispatchQueue.main.async {
            self.window?.rootViewController?.dismiss(animated: animated, completion: nil)
            self.window?.rootViewController = nil
            self.window?.isHidden = true
            self.firstWindow?.makeKeyAndVisible()
            self.window = nil
            self.alertController = nil
        }
    }
}

// In the case of view controller-based status bar style, make sure we use the same style for our view controller
private class ClearViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override var preferredStatusBarStyle: UIStatusBarStyle {
        return view.window?.windowScene?.statusBarManager?.statusBarStyle ?? .default
    }

    fileprivate override var prefersStatusBarHidden: Bool {
        return view.window?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
    }
}
