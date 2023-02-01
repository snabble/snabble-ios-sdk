//
//  IBANFormatter.swift
//  IBAN Formatter
//
//  Created by Uwe Tilemann on 29.01.23.
//

import Foundation

public protocol FormatterSelectionHint {
    var currentOffset: Int? { get set }
    var currentControlChar: IBAN.ControlChar { get }
}

public class IBANFormatter: Formatter, FormatterSelectionHint {
    public var ibanDefinition: IBANDefinition

    public var placeholder: String {
        return ibanDefinition.placeholder
    }

    public var formatString: String {
        return ibanDefinition.formatString
    }

    private var characterSet: CharacterSet {
        IBAN.validCharacterSet(ibanDefinition.country)
    }

    public var currentOffset: Int?

    public var currentControlChar: IBAN.ControlChar {
        guard let index = self.currentIndex,
                let controlChar = IBAN.ControlChar(rawValue: String(ibanDefinition.keyboardMapping[index])) else {
            return .digits
        }
        return controlChar
    }

    public init(country: String = "DE") {
        self.ibanDefinition = IBANDefinition(country: country)
            
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func placeholder(with char: Character) -> String {
        return IBAN.placeholder(ibanDefinition.country, with: char)
    }

    private func isValid(_ value: String) -> Bool {
        guard let invalidRange = value.rangeOfCharacter(from: characterSet.inverted) else {
            return true
        }
        return invalidRange.isEmpty
    }

    private func convert(string: String) -> String {
        let iban = string.replacingOccurrences(of: " ", with: "")
        let inLength = iban.count
        var offset: Int = 0
        var result = ""

        for char in String(formatString[formatString.startIndex...]) {
            guard offset < inLength else {
                continue
            }
            if char == " " {
                result.append(" ")
            } else {
                let currentIndex = iban.index(iban.startIndex, offsetBy: offset)
                result.append(String(iban[currentIndex]))
                offset += 1
            }
        }
        return result
    }

    public override func string(for obj: Any?) -> String? {
        guard let string = obj as? String else {
            return nil
        }
        return convert(string: string)
    }

    public override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
                                        for string: String,
                                        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let hexValue = convert(string: string)

        obj?.pointee = hexValue as AnyObject
        return true
    }

    public override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        guard partialString.count <= placeholder.count else { return false }

        return isValid(partialString)
    }
}

extension IBANFormatter {
    public var currentIndex: String.Index? {
        guard let offset = currentOffset, offset <= formatString.count else {
            return nil
        }
        let saveOffset = min(offset, formatString.count - 1)
        var index = formatString.index(formatString.startIndex, offsetBy: saveOffset)
        if formatString[index] == " " {
            let nextOffset = offset < formatString.count - 1 ? offset + 1 : formatString.count - 1
            index = formatString.index(formatString.startIndex, offsetBy: nextOffset)
        }
        return index
    }
}

extension IBANFormatter {
    public enum HintState: String {
        case checksum
        case bank
        case account
        case accountType
        case controlCode
        case regionCode
        case branchCode
        case miscCode

        public var message: String {
            return self.rawValue
        }
    }

    /*
     pp  zweistellige Prüfsumme
     b   Stelle der Bankleitzahl 
     d   Kontotyp 
     k   Stelle der Kontonummer 
     K   Kontrollzeichen (Großbuchstabe oder Ziffer) 
     r   Regionalcode 
     s   Stelle der Filialnummer (Branch Code / code guichet) 
     X   sonstige Funktionen
     */
    public var hintState: HintState? {
        guard let index = currentIndex else {
            return nil
        }
        let char = formatString[index]

        switch char {
        case "p":
            return .checksum
        case "b":
            return .bank
        case "k":
            return .account
        case "d":
            return .accountType
        case "K":
            return .controlCode
        case "r":
            return .regionCode
        case "s":
            return .branchCode
        case "X":
            return .miscCode
        default:
            return nil
        }
    }
}
