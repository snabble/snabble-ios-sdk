//
//  UIKitTextView.swift
//  
//
//  Created by Uwe Tilemann on 06.02.23.
//
import UIKit
import SwiftUI

public struct UIKitTextView: UIViewRepresentable {
    @Binding var text: String

    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var backgroundColor: UIColor = .tertiarySystemGroupedBackground
    var font: UIFont.TextStyle = .body

    public init(
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        returnKeyType: UIReturnKeyType = .default,
        backgroundColor: UIColor = .tertiarySystemGroupedBackground,
        font: UIFont.TextStyle
    ) {
        self._text = text
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.backgroundColor = backgroundColor
        self.font = font
    }

    public func makeUIView(context: UIViewRepresentableContext<UIKitTextView>) -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.delegate = context.coordinator

        textView.returnKeyType = returnKeyType
        textView.keyboardType = self.keyboardType
        textView.backgroundColor = backgroundColor
        textView.font = UIFont.preferredFont(forTextStyle: font)

        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator: NSObject, UITextViewDelegate {

        let control: UIKitTextView

        init(_ control: UIKitTextView) {
            self.control = control
        }

        public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            if let scrollView = textView.enclosingScrollView {
                let rect = textView.convert(textView.frame, to: scrollView )
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.5))
                    scrollView.scrollRectToVisible(rect, animated: true)
                }
            }
            return true
        }
        public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
            return true
        }
        @objc public func textViewDidChange(_ textView: UITextView) {
            control.text = textView.text ?? ""
        }
        public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if let char = text.cString(using: String.Encoding.utf8), strcmp(char, "\\n") == -82, control.returnKeyType == .done {
                textView.endEditing(true)
                return false
            }
            return true
        }
    }
}

extension UIView {
    var enclosingScrollView: UIScrollView? {
        var next: UIView? = self
        repeat {
            next = next?.superview
            if let scrollview = next as? UIScrollView {
                return scrollview
            }
        } while next != nil
        return nil
    }
}
