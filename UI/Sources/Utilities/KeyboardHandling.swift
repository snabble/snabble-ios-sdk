//
//  KeyboardHandling.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

/// frame and animation data extracted from a keyboard show/hide notification
public struct KeyboardInfo {
    public let beginFrame: CGRect
    public let endFrame: CGRect
    public let animationDuration: TimeInterval

    init?(notification: Notification) {
        guard
            let userInfo = (notification as Notification).userInfo,
            let beginFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else {
            return nil
        }

        self.beginFrame = beginFrame.cgRectValue
        self.endFrame = endFrame.cgRectValue
        self.animationDuration = duration
    }

    public var keyboardHeight: CGFloat {
        return self.endFrame.height
    }
}

@MainActor
public protocol KeyboardHandling: AnyObject {
    func keyboardWillShow(_ info: KeyboardInfo)

    func keyboardWillHide(_ info: KeyboardInfo)
}

public final class KeyboardObserver: NSObject {
    private weak var handler: KeyboardHandling?

    public required init(handler: KeyboardHandling) {
        self.handler = handler
        super.init()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @MainActor @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = KeyboardInfo(notification: notification) else {
            return
        }

        self.handler?.keyboardWillShow(info)
    }

    @MainActor @objc private func keyboardWillHide(_ notification: Notification) {
        guard let info = KeyboardInfo(notification: notification) else {
            return
        }

        self.handler?.keyboardWillHide(info)
    }
}

extension UITextField {
    @discardableResult
    func addDoneButton() -> UIToolbar {
        let keyboardToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(UITextField.endEditing(_:)))
        keyboardToolbar.items = [flexSpace, doneButton]
        keyboardToolbar.sizeToFit()
        self.inputAccessoryView = keyboardToolbar
        return keyboardToolbar
    }
}
