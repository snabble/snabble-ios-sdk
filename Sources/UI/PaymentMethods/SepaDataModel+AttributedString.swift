//
//  SepaDataModel+AttributedString.swift
//  IBAN Formatter
//
//  Created by Uwe Tilemann on 31.01.23.
//

import Foundation
import UIKit

extension SepaDataModel {
    var emptyRange: NSRange? {
        guard ibanNumber.count > 0 else {
            return nil
        }
        return NSRange(location: ibanNumber.count, length: formatter.placeholder.count-ibanNumber.count)
    }
    var inputRange: NSRange? {
        guard ibanNumber.count > 0 else {
            return nil
        }
        return NSRange(location: 0, length: ibanNumber.count)
    }
}

extension SepaDataModel {
    var inputPlaceholderString: String {
        return formatter.placeholder(with: "#")
    }

    var lineBreakMode: NSLineBreakMode {
        guard let offset = formatter.currentOffset  else {
            return .byTruncatingTail
        }
        return offset < formatter.placeholder.count/2 ? .byTruncatingTail : .byTruncatingHead
    }

    func attributedInputPlaceholder(_ placeholderString: String) -> NSAttributedString {
        let font: UIFont
        if #available(iOS 15.0, *) {
            font = .preferredFont(forTextStyle: .body)
        } else {
            font = .preferredFont(forTextStyle: placeholderString.count < 31 ? .body : .footnote)
        }
        let string = NSMutableAttributedString(
            string: placeholderString,
            attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
            ])
        if let emptyRange = emptyRange {
            string.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel], range: emptyRange)
        }
        if let inputRange = inputRange {
            string.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.label], range: inputRange)
        }
        return NSAttributedString(attributedString: string)
    }

    var attributedInputPlaceholderString: NSAttributedString {
        return attributedInputPlaceholder(inputPlaceholderString)
    }
}
