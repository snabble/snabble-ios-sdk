//
//  UIKitTextField.swift
//  
//
//  Created by Uwe Tilemann on 15.12.22.
//

import UIKit
import SwiftUI
import SnabbleCore

struct UIKitTextField: UIViewRepresentable {

    static var isSwitching = false
    static weak var endingTextField: UITextField?
    
    var label: String? = nil
    @Binding var text: String
    
    var formatter: Formatter?
    
    var focusable: Binding<[Bool]>?
    var isSecureTextEntry: Binding<Bool>?

    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .words
    var textContentType: UITextContentType?

    var tag: Int?
    var inputAccessoryView: UIToolbar?
    
    var onCommit: (() -> Void)?

    func makeUIView(context: UIViewRepresentableContext<UIKitTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        
        textField.placeholder = self.label
        textField.keyboardType = self.formatter != nil ? .numberPad : .default
        textField.returnKeyType = returnKeyType
        textField.autocapitalizationType = autocapitalizationType
        textField.keyboardType = keyboardType
        textField.isSecureTextEntry = isSecureTextEntry?.wrappedValue ?? false
        textField.textContentType = textContentType
        if let tag = tag {
            textField.tag = tag
        }
        textField.inputAccessoryView = inputAccessoryView
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isSecureTextEntry = isSecureTextEntry?.wrappedValue ?? false
        
        if let focusable = focusable?.wrappedValue {
            var resignResponder = true
            
            for (index, focused) in focusable.enumerated() {
                if uiView.tag == index && focused {
                    if !uiView.isFirstResponder, uiView != Self.endingTextField {
                        DispatchQueue.main.async {
                            uiView.becomeFirstResponder()
                        }
                    }
                    resignResponder = false
                    break
                }
            }
            if resignResponder, uiView.isFirstResponder {
                DispatchQueue.main.async {
                    uiView.resignFirstResponder()
                }
            }
        }
    }
        
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UITextFieldDelegate {
        
        let control: UIKitTextField
        
        init(_ control: UIKitTextField) {
            self.control = control
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            UIKitTextField.endingTextField = nil
            guard var focusable = control.focusable?.wrappedValue else { return }
            
            for index in 0...(focusable.count - 1) {
                focusable[index] = (textField.tag == index)
            }
            if UIKitTextField.isSwitching {
                UIKitTextField.isSwitching = false
            } else {
                control.focusable?.wrappedValue = focusable
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard var focusable = control.focusable?.wrappedValue else {
                textField.resignFirstResponder()
                return true
            }
            
            for index in 0...(focusable.count - 1) {
                focusable[index] = (textField.tag + 1 == index)
            }
            
            if control.focusable?.wrappedValue != focusable {
                UIKitTextField.isSwitching = true
                control.focusable?.wrappedValue = focusable
            }
            if textField.tag == focusable.count - 1 {
                textField.resignFirstResponder()
            }
            
            return true
        }
        
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            endingTextField = textField
            return true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            self.control.onCommit?()
        }
                
        @objc func textFieldDidChange(_ textField: UITextField) {
            control.text = textField.text ?? ""
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let text = textField.text,
                  let textRange = Range(range, in: text) else {
                return true
            }
            
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            
            var backSpace = false
            
            if let char = string.cString(using: String.Encoding.utf8) {
                let isBackSpace = strcmp(char, "\\b")
                if isBackSpace == -92 {
                    backSpace = true
                }
            }
            if string.isEmpty && backSpace {           // backspace inserts nothing, but we need to accept it.
                return true
            }
            guard let formatter = control.formatter else {
                return true
            }
            
            if let formattedText = formatter.string(for: updatedText) {
                var textFieldRange: UITextRange? = nil
                
                if range.location < formattedText.lengthOfBytes(using: .utf8) - 1,
                   let oldFieldRange = textField.selectedTextRange,
                   let newStart = textField.position(from: oldFieldRange.start, offset: 1),
                   let newEnd = textField.position(from: oldFieldRange.end, offset: 1),
                   let newRange = textField.textRange(from: newStart, to: newEnd) {
                    textFieldRange = newRange
                }

                textField.text = formattedText
                control.text = formattedText
                
                if let newRange = textFieldRange {
                    textField.selectedTextRange = newRange
                }
                return false
            }
            return true
        }
    }
}
