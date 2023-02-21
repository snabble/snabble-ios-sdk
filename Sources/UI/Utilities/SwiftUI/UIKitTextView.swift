//
//  UIKitTextView.swift
//  
//
//  Created by Uwe Tilemann on 06.02.23.
//
import UIKit
import SwiftUI

struct UIKitTextView: UIViewRepresentable {
    @Binding var text: String

    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var backgroundColor: UIColor = .tertiarySystemGroupedBackground
    var font: UIFont.TextStyle = .body

    func makeUIView(context: UIViewRepresentableContext<UIKitTextView>) -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.delegate = context.coordinator

        textView.returnKeyType = returnKeyType
        textView.keyboardType = self.keyboardType
        textView.backgroundColor = backgroundColor
        textView.font = UIFont.preferredFont(forTextStyle: font)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {

        let control: UIKitTextView

        init(_ control: UIKitTextView) {
            self.control = control
        }

        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            if let scrollView = textView.enclosingScrollView {
                let rect = textView.convert(textView.frame, to: scrollView )
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollView.scrollRectToVisible(rect, animated: true)
                }
            }
            return true
        }
        func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
            return true
        }
        @objc func textViewDidChange(_ textView: UITextView) {
            control.text = textView.text ?? ""
        }
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
