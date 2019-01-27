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
    /// the embedded data of the code (weight, price or amount), the value is the length of the field
    case embed(Int)
    /// the embedded price of one `referenceUnit` worth of the product. For weight-dependent prices, this is usually the price per kilogram.
    /// The value is the length of the field
    case price(Int)
    /// unknown plain text that will be ignored (e.g. checksums that we can't/won't verify)
    /// The value is the length of the field
    case ignore(Int)
    /// represents the internal 5-digit-checksum for embedded data in an EAN-13, which is always one character.
    case internalChecksum
    /// match the entire string - used only in our internal "default" template
    case catchall

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
                case "embed": self = .embed(len)
                case "price": self = .price(len)
                case "_": self = .ignore(len)
                case "i": self = .internalChecksum
                case "*": self = .catchall
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
        case .embed(let len): return "(\\d{\(len)})"
        case .price(let len): return "(\\d{\(len)})"
        case .ignore(let len): return "(.{\(len)})"
        case .internalChecksum: return "(\\d)"
        case .catchall: return "(.*)"
        }
    }

    /// get the length of this component
    var length: Int {
        switch self {
        case .plainText(let str): return str.count
        case .code(let codeType): return codeType.length
        case .embed(let len): return len
        case .price(let len): return len
        case .ignore(let len): return len
        case .internalChecksum: return 1
        case .catchall: return 0
        }
    }

    /// is this a `code` component?
    var isCode: Bool {
        switch self {
        case .code: return true
        default: return false
        }
    }

    /// is this an `embed` component?
    var isEmbed: Bool {
        switch self {
        case .embed: return true
        default: return false
        }
    }

    /// is this a `catchAll` component?
    var isCatchall: Bool {
        switch self {
        case .catchall: return true
        default: return false
        }
    }

    /// get a simple but unique key for each type
    fileprivate var key: Int {
        switch self {
        case .plainText: return 0
        case .code: return 1
        case .embed: return 2
        case .price: return 3
        case .ignore: return 4
        case .internalChecksum: return 5
        case .catchall: return 6
        }
    }
}

/// a `CodeTemplate` represents a fully parsed template expression, like "01{code:ean14}"
public struct CodeTemplate {
    /// the template's identifier
    public let id: String
    /// the original template string
    public let template: String
    /// the expected length of a string that could possibly match
    public let expectedLength: Int
    /// the parsed components in left-to-right order
    fileprivate let components: [TemplateComponent]

    /// RE for a token
    private static let token = try! NSRegularExpression(pattern: "^(\\{.*?\\})", options: [])
    /// RE for plaintext
    private static let plaintext = try! NSRegularExpression(pattern: "^([^{]+)", options: [])
    private static let regexps = [ token, plaintext ]

    static let `default` = CodeTemplate("default", "{*}")!

    init?(_ id: String, _ template: String) {
        self.id = id
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
        self.expectedLength = components.reduce(0) { $0 + $1.length }

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

        // when {i} is present, check for {embed:5}
        if count[TemplateComponent.internalChecksum.key] != nil {
            guard let len = components.first(where: { $0.isEmbed })?.length, len == 5 else {
                return nil
            }
        }
    }

    /// check if a given string matches this template
    ///
    /// - Parameter string: the code to match
    /// - Returns: a `ParseResult` object, or `nil` if the code didn't match
    func match(_ string: String) -> ParseResult? {
        if self.expectedLength > 0 && self.expectedLength != string.count {
            return nil
        }
        let regexStr = "^" + self.components.map { $0.regex }.joined() + "$"
        let matches = self.regexMatches(regexStr, string)
        if matches.count == self.components.count {
            let result = ParseResult(self, matches)
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
            if let match = matches.first {
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

/// the matcher's result
public struct ParseResult {
    /// the template we matched against
    public let template: CodeTemplate

    fileprivate typealias Entry = (templateComponent: TemplateComponent, value: String)
    fileprivate let entries: [Entry]

    init(_ template: CodeTemplate, _ values: [String]) {
        assert(template.components.count == values.count)
        self.template = template
        self.entries = Array(zip(template.components, values))
    }

    /// return the (part of the) code we should use for database lookups
    public var lookupCode: String {
        if let entry = self.entries.first(where: { $0.templateComponent.isCode }) {
            return entry.value
        }
        if let entry = self.entries.first(where: { $0.templateComponent.isCatchall }) {
            return entry.value
        }
        return ""
    }

    /// is this result valid?
    /// (it is if all components are valid)
    public var isValid: Bool {
        for component in self.entries {
            if !self.valid(component) {
                return false
            }
        }
        return true
    }

    public var embeddedData: Int? {
        guard let entry = self.entries.first(where: { $0.templateComponent.isEmbed }) else {
            return nil
        }
        return Int(entry.value)
    }

    /// embed data into a scanned code in place of the `embed` placeholder
    public func embed(_ data: Int) -> String {
        var result = ""
        var embeddedData = ""
        var needChecksum = false
        for entry in self.entries {
            switch entry.templateComponent {
            case .embed:
                let str = String(data)
                let padding = String(repeatElement("0", count: entry.templateComponent.length - str.count))
                embeddedData = padding + str
                result.append(embeddedData)
            case .internalChecksum:
                needChecksum = true
                result.append(entry.value)
            default:
                result.append(entry.value)
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
    private func valid(_ entry: Entry) -> Bool {
        switch entry.templateComponent {
        case .code(let codeType):
            switch codeType {
            case .ean8, .ean13, .ean14:
                return EAN.parse(entry.value) != nil
            case .untyped(let len):
                return entry.value.count == len
            }
        case .internalChecksum:
            guard let embedComponent = self.entries.first(where: { $0.templateComponent.isEmbed }) else {
                return false
            }
            let digits = embedComponent.value.compactMap { Int(String($0)) }
            let checksum = EAN13.internalChecksum5(digits)
            return String(checksum) == entry.value
        default:
            return true
        }
    }
}

public struct CodeMatcher {
    static let builtinTemplates = [
        "ean13_instore":        "2{code:5}{_}{embed:5}{_}",
        "ean13_instore_chk":    "2{code:5}{i}{embed:5}{_}",
        "german_print":         "4{code:2}{_:5}{embed:4}{_}",
        "ean14_code128":        "01{code:ean14}",
        "edeka_discount":       "97{code:ean13}{embed:6}{_}",
    ]

    public static var customTemplates = [String: String]()

    private static let templates = prepareTemplates()

    static func prepareTemplates() -> [CodeTemplate] {
        var templates = [CodeTemplate]()

        let allTemplates = builtinTemplates.merging(customTemplates, uniquingKeysWith: { (_, new) in return new })

        allTemplates.forEach { id, tmpl in
            guard let template = CodeTemplate(id, tmpl) else {
                return
            }

            templates.append(template)
        }

        // sort by length
        templates.sort { $0.expectedLength < $1.expectedLength }

        // add the catchall template last
        templates.append(CodeTemplate.default)

        return templates
    }

    public static func match(_ code: String) -> [ParseResult] {
        var results = [ParseResult]()
        for template in templates {
            if let result = template.match(code) {
                results.append(result)
            }
        }
        return results
    }

    public static func createInstoreEan(_ template: String, _ code: String, _ data: Int) -> String? {
        guard let template = templates.first(where: { $0.id == template }) else {
            return nil
        }

        let rawEmbed = String(data)
        let padding = String(repeating: "0", count: 5 - rawEmbed.count)
        let embed = padding + rawEmbed

        var result = ""
        for c in template.components {
            switch c {
            case .plainText(let str):
                result.append(str)
            case .code:
                result.append(code)
            case .internalChecksum:
                let embedDigits = embed.map { Int(String($0))! }
                let check = EAN13.internalChecksum5(embedDigits)
                result.append(String(check))
            case .embed(let len):
                result.append(String(repeating: "0", count: len))
            case .ignore(let len):
                result.append(String(repeating: "0", count: len))
            default: ()
            }
        }

        let ean = EAN13(String(result.prefix(7)) + embed)
        return ean?.code
    }
}
