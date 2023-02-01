/* 
  IBANFormatter+TextField.strings
  IBAN Formatter

  Created by Uwe Tilemann on 29.01.23.
  
*/
import Foundation
import UIKit
import SnabbleCore

extension IBANFormatter.HintState {
    public var localizedString: String {
        return Asset.localizedString(forKey: "Snabble.Payment.SEPA.Hint.\(message)")
    }
}

extension IBANFormatter: TextChangeFormatter {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let text = textField.text else {
            return true
        }
        if text.count == formatString.count, !IBAN.verify(iban: ibanDefinition.country + text) {
            return false
        }
        return true
    }

    // swiftlint:disable large_tuple
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> (updatedText: String?, updatedRange: UITextRange?, shouldChange: Bool) {
        guard let text = textField.text,
              let textRange = Range(range, in: text) else {
            return (nil, nil, true)
        }
        let updatedText = text.replacingCharacters(in: textRange, with: string)

        if let formattedText = self.string(for: updatedText) {
            var textFieldRange: UITextRange?
            let length = string.count

            if range.location < formattedText.count - 1, NSMaxRange(range) + length < formattedText.count {
                let offset = (formattedText.count - updatedText.count)
                let inserted = formattedText[formattedText.index(formattedText.startIndex, offsetBy: range.location)...formattedText.index(formattedText.startIndex, offsetBy: range.location + length - 1)]

                let spaceInserted = inserted != string

                if let oldFieldRange = textField.selectedTextRange,
                   let newStart = textField.position(from: oldFieldRange.start, offset: spaceInserted ? offset + length : length),
                   let newEnd = textField.position(from: oldFieldRange.end, offset: spaceInserted ? offset + length : length),
                   let newRange = textField.textRange(from: newStart, to: newEnd) {
                    textFieldRange = newRange
                }
            }
            return (formattedText, textFieldRange, false)
        }
        return (nil, nil, true)
    }
    // swiftlint:enable large_tuple
}
