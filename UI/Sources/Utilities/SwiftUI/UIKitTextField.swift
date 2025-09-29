//
//  UIKitTextField.swift
//  IBAN Formatter
//
//  Created by Uwe Tilemann on 26.01.23.
//

import UIKit
import SwiftUI
import SnabbleCore

extension UITextField {
    var cursorOffset: Int? {
        guard let range = selectedTextRange else { return nil }
        return offset(from: beginningOfDocument, to: range.start)
    }
    var cursorIndex: String.Index? {
        guard let location = cursorOffset, let text = text else { return nil }
        return Range(.init(location: location, length: 0), in: text)?.lowerBound
    }
    var cursorDistance: Int? {
        guard let cursorIndex = cursorIndex, let text = text else { return nil }
        return text.distance(from: text.startIndex, to: cursorIndex)
    }
}

@MainActor
protocol TextChangeFormatter {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
    // swiftlint:disable large_tuple
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> (updatedText: String?, updatedRange: UITextRange?, shouldChange: Bool)
    // swiftlint:enable large_tuple
}

extension FormatterSelectionHint {
    @MainActor func updateKeyboard(for textField: UITextField) {
        if let currentKeyboard: UIKeyboardType = self.currentControlChar == .digits ? .numberPad : .default,
           currentKeyboard != textField.keyboardType {
            textField.keyboardType = currentKeyboard
            textField.autocapitalizationType = self.currentControlChar == .uppercaseLetters ? .allCharacters : .none
            textField.resignFirstResponder()
            textField.becomeFirstResponder()
        }
    }
}

public extension Notification.Name {
    static let textFieldDidBeginEditing = Notification.Name("textFieldDidBeginEditing")
}

struct UIKitTextField<Content: View>: UIViewRepresentable {

    var label: String?
    @Binding var text: String

    var formatter: Formatter?
    var isSecureTextEntry: Binding<Bool>?

    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .words
    var textContentType: UITextContentType?
    var textAlignment: NSTextAlignment = .left

    var tag: Int?
    var content: Content?
    var font: UIFont?
    var onSubmit: (() -> Void)?

    init(_ label: String? = nil,
         text: Binding<String>,
         formatter: Formatter? = nil,
         isSecureTextEntry: Binding<Bool>? = nil,
         keyboardType: UIKeyboardType = .default,
         returnKeyType: UIReturnKeyType = .default,
         autocapitalizationType: UITextAutocapitalizationType = .words,
         textContentType: UITextContentType? = nil,
         textAlignment: NSTextAlignment = .left,
         tag: Int? = nil,
         font: UIFont? = nil,
         onSubmit: (() -> Void)? = nil,
         content: (() -> Content)? = nil) {
        self.label = label
        self._text = text
        self.formatter = formatter
        self.isSecureTextEntry = isSecureTextEntry
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.autocapitalizationType = autocapitalizationType
        self.textContentType = textContentType
        self.textAlignment = textAlignment
        self.tag = tag
        self.font = font
        self.onSubmit = onSubmit
        self.content = content?()
    }

    func makeUIView(context: UIViewRepresentableContext<UIKitTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator

        textField.placeholder = self.label
        textField.returnKeyType = returnKeyType
        textField.autocapitalizationType = autocapitalizationType

        if let formatter = self.formatter as? FormatterSelectionHint {
            textField.keyboardType = formatter.currentControlChar == .digits ? .numberPad : .default
        } else {
            textField.keyboardType = self.keyboardType
        }
        textField.isSecureTextEntry = isSecureTextEntry?.wrappedValue ?? false
        textField.textContentType = textContentType
        textField.textAlignment = textAlignment
        
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground

        if let tag = tag {
            textField.tag = tag
        }
        if let font = font {
            textField.font = font
        }
        if let content = self.content {
            let contentView: UIView = UIHostingController(rootView: content).view
            contentView.frame = CGRect(x: 0, y: 0, width: 280, height: 44)
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.isOpaque = false
            contentView.backgroundColor = .clear
            contentView.sizeToFit()

            let keyboardToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
            let leftButton = UIBarButtonItem(customView: contentView)
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: textField, action: #selector(Coordinator.endEditing(_:)))
            keyboardToolbar.items = [leftButton, flexSpace, doneButton]
            keyboardToolbar.sizeToFit()

            textField.inputAccessoryView = keyboardToolbar

        }
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.endEditing(_:)), for: .editingDidEnd)
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isSecureTextEntry = isSecureTextEntry?.wrappedValue ?? false
        uiView.font = self.font
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {

        let control: UIKitTextField

        init(_ control: UIKitTextField) {
            self.control = control
        }
        
        func textFieldShouldReturn(_: UITextField) -> Bool {
            if let onSubmit = control.onSubmit {
                onSubmit()
            }
            return true
        }
        
        @objc func endEditing(_ textField: UITextField) {
            if textField.endEditing(true), let onSubmit = control.onSubmit {
                onSubmit()
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            NotificationCenter.default.post(name: .textFieldDidBeginEditing, object: textField)
        }
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            if let formatter = control.formatter as? TextChangeFormatter {
                return formatter.textFieldShouldEndEditing(textField)
            }
            return true
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            control.text = textField.text ?? ""
        }

        @objc func textFieldDidChangeSelection(_ textField: UITextField) {
            guard var formatter = control.formatter as? FormatterSelectionHint else {
                return
            }
            formatter.currentOffset = textField.cursorOffset
            formatter.updateKeyboard(for: textField)
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {            
            if let char = string.cString(using: String.Encoding.utf8) {
                let isBackSpace = strcmp(char, "\\b")
                if string.isEmpty, isBackSpace == -92 {
                    return true
                } else if strcmp(char, "\\n") == -82 {
                    return true
                }
            }
            guard let formatter = control.formatter as? TextChangeFormatter else {
                return true
            }

            let result = formatter.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
            if result.shouldChange == false, let updatedText = result.updatedText {
                textField.text = updatedText
                self.textFieldDidChange(textField)
            }
            if let updatedRange = result.updatedRange {
                DispatchQueue.main.async {
                    textField.selectedTextRange = updatedRange
                }
            }
            return result.shouldChange
        }
    }
}

extension UIKitTextField where Content == EmptyView {
    init(_ label: String? = nil,
         text: Binding<String>,
         formatter: Formatter? = nil,
         isSecureTextEntry: Binding<Bool>? = nil,
         keyboardType: UIKeyboardType = .default,
         returnKeyType: UIReturnKeyType = .default,
         autocapitalizationType: UITextAutocapitalizationType = .words,
         textContentType: UITextContentType? = nil,
         textAlignment: NSTextAlignment = .left,
         tag: Int? = nil,
         font: UIFont? = nil,
         onSubmit: (() -> Void)? = nil) {
        self.label = label
        self._text = text
        self.formatter = formatter
        self.isSecureTextEntry = isSecureTextEntry
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.autocapitalizationType = autocapitalizationType
        self.textContentType = textContentType
        self.textAlignment = textAlignment
        self.tag = tag
        self.font = font
        self.onSubmit = onSubmit
        self.content = nil
    }
}
