//
//  CodeTemplates.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

// template parsing and matching, see
// https://github.com/snabble/product-ng/blob/master/code-templates.md

fileprivate enum CodeType: Equatable {
    case ean8
    case ean13
    case ean14
    case untyped(Int)

    init?(_ code: String) {
        switch code {
        case "ean8": self = .ean8
        case "ean13": self = .ean13
        case "ean14": self = .ean14
        default:
            guard let len = Int(code), len > 0 else {
                return nil
            }
            self = .untyped(len)
        }
    }

    var length: Int {
        switch self {
        case .ean8: return 8
        case .ean13: return 13
        case .ean14: return 14
        case .untyped(let len): return len
        }
    }
}

/// the constituent parts of a template
fileprivate enum TemplateComponent {
    /// known plain text that will be ignored (e.g. "01" from "01{code:ean14}". The value is the actual string
    case plainText(String)
    /// the code part of the template. this is what we will use to look up products in the database
    /// may specify a known code ("ean8", "ean13", or "ean14") or a length
    case code(CodeType)
    /// the embedded data of the code (not necessarily always a weight), the value is the length of the field
    case weight(Int)
    /// the embedded price of one `referenceUnit` worth of the product. For weight-dependenent prices, this is usually the price per kilogram.
    /// The value is the length of the field
    case price(Int)
    /// unknown plain text that will be ignored (e.g. checksums that we can't/won't verify)
    /// The value is the length of the field
    case ignore(Int)
    /// represents the internal 5-digit-checksum for embedded data in an EAN-13, which is always one character.
    case internalChecksum

    /// parse one template component. properties look like "{name:length}", everything else is considered plain text
    init?(_ str: String) {
        if str.prefix(1) == "{" {
            // strip off the braces and split at the first ":"
            let parts = str.dropFirst().dropLast().components(separatedBy: ":")
            let lengthPart = parts.count > 1 ? parts[1] : "1"
            let length = Int(lengthPart)

            if parts[0] == "code" {
                guard let codeType = CodeType(lengthPart) else {
                    return nil
                }
                self = .code(codeType)
            } else {
                guard let len = length, len > 0 else {
                    return nil
                }
                switch parts[0] {
                case "weight": self = .weight(len)
                case "price": self = .price(len)
                case "_": self = .ignore(len)
                case "i": self = .internalChecksum
                default: return nil
                }
            }
        } else {
            self = .plainText(str)
        }
    }

    /// get the regular expression that matches this component
    var regex: String {
        switch self {
        case .plainText(let str): return "(\\Q\(str)\\E)"
        case .code(let codeType): return "(\\d{\(codeType.length)})"
        case .weight(let len): return "(\\d{\(len)})"
        case .price(let len): return "(\\d{\(len)})"
        case .ignore(let len): return "(.{\(len)})"
        case .internalChecksum: return "(\\d)"
        }
    }

    /// get the length of this component
    var length: Int {
        switch self {
        case .plainText(let str): return str.count
        case .code(let codeType): return codeType.length
        case .weight(let len): return len
        case .price(let len): return len
        case .ignore(let len): return len
        case .internalChecksum: return 1
        }
    }

    /// is this a `code` component?
    var isCode: Bool {
        switch self {
        case .code: return true
        default: return false
        }
    }

    /// is this a `weight` component?
    var isWeight: Bool {
        switch self {
        case .weight: return true
        default: return false
        }
    }

    /// get a simple but unique key for each type
    fileprivate var key: Int {
        switch self {
        case .plainText: return 0
        case .code: return 1
        case .weight: return 2
        case .price: return 3
        case .ignore: return 4
        case .internalChecksum: return 5
        }
    }
}

/// a `CodeTemplate` represents a fully parsed template expression, like "01{code:ean14"
struct CodeTemplate {
    /// the template's identifier
    let id: String
    /// the original template string
    let template: String
    /// the parsed components in left-to-right order
    fileprivate let components: [TemplateComponent]

    /// RE for a token
    private static let token = try! NSRegularExpression(pattern: "^(\\{.*?\\})", options: [])
    /// RE for plaintext
    private static let plaintext = try! NSRegularExpression(pattern: "^([^{]+)", options: [])
    private static let regexps = [ token, plaintext ]

    init?(_ id: String, _ template: String) {
        self.id = ""
        self.template = template
        var str = template

        var components = [TemplateComponent]()
        while str.count > 0 {
            var foundMatch = false
            for re in CodeTemplate.regexps {
                let result = re.matches(in: str, options: [], range: NSRange(location: 0, length: str.count))
                if result.count == 0 {
                    continue
                }
                let range = result[0].range(at: 0)
                let token = String(str.prefix(range.length))
                if let component = TemplateComponent(token) {
                    components.append(component)
                } else {
                    return nil
                }
                foundMatch = true
                str = String(str.dropFirst(range.length))
                continue
            }
            if !foundMatch {
                return nil
            }
        }

        guard components.count > 0 else {
            return nil
        }
        self.components = components

        // further checks:
        // each component may occur 0 or 1 times, except _
        var count = [Int: Int]()
        for comp in components {
            if case .ignore = comp {
                // skip .ignore
            } else {
                count[comp.key, default: 0] += 1
            }
        }

        if count.values.first(where: { $0 > 1 }) != nil {
            return nil
        }

        // when {i} is present, check for {weight:5}
        if count[TemplateComponent.internalChecksum.key] != nil {
            guard let len = components.first(where: { $0.isWeight })?.length, len == 5 else {
                return nil
            }
        }
    }

    /// total length of all components
    var expectedLength: Int {
        return components.reduce(0) { $0 + $1.length }
    }

    /// check if a given string matches this template
    ///
    /// - Parameter string: the code to match
    /// - Returns: a `ParseResult` object, or `nil` if the code didn't match
    func match(_ string: String) -> ParseResult? {
        let regexStr = self.components.map { $0.regex }.joined()
        let matches = self.regexMatches(regexStr, string)
        if matches.count == self.components.count {
            let components = zip(self.components, matches).map { ParsedComponent(template: $0.0, value: $0.1) }
            let result = ParseResult(components: components)
            return result.isValid ? result : nil
        } else {
            return nil
        }
    }

    /// check if `text` matches `regexStr`,
    ///
    /// - Parameters:
    ///   - regexStr: the regex to match against
    ///   - text: the text to match
    /// - Returns: array containing the text of all matched capture groups
    private func regexMatches(_ regexStr: String, _ text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regexStr, options: [])
            let range = NSRange(location: 0, length: text.count)
            let matches = regex.matches(in: text, options: [], range: range)
            if matches.count == 1, let match = matches.first {
                var result = [String]()
                for r in 1 ..< match.numberOfRanges {
                    if let range = Range(match.range(at: r), in: text) {
                        let str = String(text[range])
                        result.append(str)
                    }
                }
                return result
            }
        } catch {
            print(error)
        }
        return []
    }
}

/// the matcher's result for one component
struct ParsedComponent {
    /// the component that we matched against
    fileprivate let template: TemplateComponent
    /// the matched value
    let value: String
}

/// the matcher's result
struct ParseResult {
    /// matched components, in left-to-right order
    let components: [ParsedComponent]

    /// return the (part of the) code we should use for database lookups
    var lookupCode: String {
        guard let codeComponent = self.components.first(where: { $0.template.isCode }) else {
            return ""
        }

        return codeComponent.value
    }

    /// is this result valid?
    /// (it is if all components are valid)
    var isValid: Bool {
        for comp in self.components {
            if !self.valid(comp) {
                return false
            }
        }
        return true
    }

    /// embed data into a scanned code in place of the `weight` placeholder
    func embed(_ data: Int) -> String {
        var result = ""
        var embeddedData = ""
        var needChecksum = false
        for component in components {
            switch component.template {
            case .weight:
                let str = String(data)
                let padding = String(repeatElement("0", count: component.template.length - str.count))
                embeddedData = padding + str
                result.append(embeddedData)
            case .internalChecksum:
                needChecksum = true
                result.append(component.value)
            default:
                result.append(component.value)
            }
        }

        // calculate EAN-13 checksum(s)
        if result.count == 13 && embeddedData.count == 5 {
            if needChecksum {
                let embedDigits = embeddedData.map { Int(String($0))! }
                let check = EAN13.internalChecksum5(embedDigits)
                result = String(result.prefix(6) + String(check) + result.suffix(6))
            }
            if let ean = EAN13(String(result.prefix(12))) {
                return ean.code
            }
        }
        return result
    }

    /// is this component's value valid?
    private func valid(_ component: ParsedComponent) -> Bool {
        switch component.template {
        case .code(let codeType):
            switch codeType {
            case .ean8, .ean13, .ean14:
                return EAN.parse(component.value, nil) != nil
            case .untyped(let len):
                return component.value.count == len
            }
        case .internalChecksum:
            guard let weightComponent = self.components.first(where: { $0.template.isWeight }) else {
                return false
            }
            let digits = weightComponent.value.compactMap { Int(String($0)) }
            let checksum = EAN13.internalChecksum5(digits)
            return String(checksum) == component.value
        default:
            return true
        }
    }
}

//struct XXXX {
//    static let builtinTemplates = [
//        CodeTemplate("ean13_instore", "{code:5}{_:8}")!,
//        CodeTemplate("ean13_instore_chk", "{code:5}{i}{_:7}")!,
//        CodeTemplate("edeka_discount", "97{code:ean13}{price:6}{_}")!
//    ]
//
//    static var allTemplates = [CodeTemplate]()
//
//    static func prepare(_ templates: [CodeTemplate]) {
//        allTemplates = builtinTemplates + templates
//        allTemplates.sort { $0.expectedLength < $1.expectedLength }
//    }
//}
