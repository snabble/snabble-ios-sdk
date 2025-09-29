//
//  CodeTemplates.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// template parsing and matching, see
// https://github.com/snabble/product-ng/blob/master/code-templates.md

private enum CodeType: Equatable {
    case ean8
    case ean13
    case ean14
    case untyped(Int)
    case matchAll
    case matchConstant(String)

    init?(_ code: String) {
        switch code {
        case "*":
            self = .matchAll
        case "ean8":
            self = .ean8
        case "ean13":
            self = .ean13
        case "ean14":
            self = .ean14
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
        case .matchAll: return 0
        case .matchConstant(let str): return str.count
        }
    }
}

private enum IgnoreLength {
    case length(Int)
    case ignoreAll

    init?(_ code: String) {
        switch code {
        case "*":
            self = .ignoreAll
        default:
            guard let len = Int(code), len > 0 else {
                return nil
            }
            self = .length(len)
        }
    }

    var length: Int {
        switch self {
        case .length(let len): return len
        case .ignoreAll: return 0
        }
    }
}

/// the constituent parts of a template
private enum TemplateComponent {
    /// known plain text that will be ignored (e.g. "01" from "01{code:ean14}". The value is the actual string
    case plainText(String)
    /// the code part of the template. this is what we will use to look up products in the database
    /// may specify a known code ("ean8", "ean13", or "ean14") or a length
    case code(CodeType)
    /// the embedded data of the code (weight, price or amount), the value is the length of the field
    case embed(Int)
    /// the embedded data of the code (weight, price or amount), the value is the length of the field.
    /// When extracting the value from a scanned code, it will be multiplied by 100
    case embed100(Int)
    /// the embedded data of the code (weight, price or amount), the values are the number of integer and fraction digits
    /// When extracting the value from a scanned code, it will be represented as a `DecimalNumber`
    case embedDecimal(Int, Int)
    /// the embedded price of one `referenceUnit` worth of the product. For weight-dependent prices, this is usually the price per kilogram.
    /// The value is the length of the field
    case price(Int)
    /// unknown plain text that will be ignored (e.g. checksums that we can't/won't verify)
    /// The value is the length of the field
    case ignore(IgnoreLength)
    /// represents the internal 5-digit-checksum for embedded data in an EAN-13, which is always one character.
    case internalChecksum
    /// represents the check digit for an EAN-8, EAN-13 or EAN-14. always one character, and must be the last component
    case eanChecksum

    /// parse one template component. properties look like "{name:length}", everything else is considered plain text
    init?(_ str: String) {
        if str.prefix(1) == "{" {
            // strip off the braces
            let base = str.dropFirst().dropLast()
            // and split at the first possible separator
            let separators = CharacterSet(charactersIn: ":=")
            let parts = base.components(separatedBy: separators)

            let lengthPart = parts.count > 1 ? parts[1] : "1"
            let length = Int(lengthPart)

            let token = parts[0]

            if token == "code" {
                if base.contains("=") {
                    let codeType = CodeType.matchConstant(lengthPart)
                    self = .code(codeType)
                    return
                }

                guard let codeType = CodeType(lengthPart) else {
                    return nil
                }
                self = .code(codeType)
            } else if token == "embed" {
                let digits = lengthPart.components(separatedBy: ".").compactMap { Int($0) }.filter { $0 > 0 }
                switch digits.count {
                case 1: self = .embed(digits[0])
                case 2: self = .embedDecimal(digits[0], digits[1])
                default: return nil
                }
            } else if token == "_" {
                guard let ignoreLength = IgnoreLength(lengthPart) else {
                    return nil
                }
                self = .ignore(ignoreLength)
            } else {
                guard let len = length, len > 0 else {
                    return nil
                }
                switch token {
                case "embed100": self = .embed100(len)
                case "price": self = .price(len)
                case "i": self = .internalChecksum
                case "ec": self = .eanChecksum
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
        case .code(let codeType):
            switch codeType {
            case .matchAll:
                return "(.*)"
            case .matchConstant(let constant):
                return "(\\Q\(constant)\\E)"
            default:
                return "(.{\(codeType.length)})"
            }
        case .embed(let len): return "(\\d{\(len)})"
        case .embed100(let len): return "(\\d{\(len)})"
        case .embedDecimal(let intDigits, let fractionDigits): return "(\\d{\(intDigits + fractionDigits)})"
        case .price(let len): return "(\\d{\(len)})"
        case .ignore(let len):
            switch len {
            case .ignoreAll: return "(.*)"
            case .length(let len): return "(.{\(len)})"
            }
        case .internalChecksum: return "(\\d)"
        case .eanChecksum: return "(\\d)"
        }
    }

    /// get the length of this component
    var length: Int {
        switch self {
        case .plainText(let str): return str.count
        case .code(let codeType): return codeType.length
        case .embed(let len): return len
        case .embedDecimal(let intDigits, let fractionDigits): return intDigits + fractionDigits
        case .embed100(let len): return len
        case .price(let len): return len
        case .ignore(let ignoreLength): return ignoreLength.length
        case .internalChecksum: return 1
        case .eanChecksum: return 1
        }
    }

    /// is this a `code` component?
    var isCode: Bool {
        switch self {
        case .code: return true
        default: return false
        }
    }

    /// is this an `embed` integer component?
    var isEmbed: Bool {
        switch self {
        case .embed, .embed100: return true
        default: return false
        }
    }

    /// is this an `embed` decimal component?
    var isDecimal: Bool {
        switch self {
        case .embedDecimal: return true
        default: return false
        }
    }

    /// is this a `price` component?
    var isPrice: Bool {
        switch self {
        case .price: return true
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
        case .embed100: return 6
        case .eanChecksum: return 7
        case .embedDecimal: return 8
        }
    }
}

public struct EmbeddedDecimal {
    public let integerDigits: Int
    public let fractionDigits: Int
    public let value: Int
}

/// a `CodeTemplate` represents a fully parsed template expression, like "01{code:ean14}"
public struct CodeTemplate: Sendable {
    /// the template's identifier
    public let id: String
    /// the original template string
    public let template: String
    /// the expected length of a string that could possibly match (if 0, the lenth is undetermined)
    public let expectedLength: Int
    /// the parsed components in left-to-right order
    fileprivate let components: [TemplateComponent]

    // swiftlint:disable force_try
    /// RE for a token
    private static let token = try! NSRegularExpression(pattern: "^(\\{.*?\\})", options: [])
    /// RE for plaintext
    private static let plaintext = try! NSRegularExpression(pattern: "^([^{^}]+)", options: [])
    private static let regexps = [ token, plaintext ]
    // swiftlint:enable force_try

    init?(_ id: String, _ template: String) {
        self.id = id
        self.template = template
        var str = template

        var components = [TemplateComponent]()
        while !str.isEmpty {
            var foundMatch = false
            for regExp in CodeTemplate.regexps {
                let result = regExp.matches(in: str, options: [], range: NSRange(location: 0, length: str.count))
                if result.isEmpty {
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

        guard !components.isEmpty else {
            return nil
        }
        self.components = components

        // if any component is a "match all", our expected length is undetermined
        if components.first(where: { $0.length == 0 }) != nil {
            self.expectedLength = 0
        } else {
            self.expectedLength = components.reduce(0) { $0 + $1.length }
        }

        // further checks:
        // each component may occur 0 or 1 times, except _ (ignore) and plainText
        var count = [Int: Int]()
        for comp in components {
            switch comp {
            case .ignore, .plainText: ()
            default: count[comp.key, default: 0] += 1
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

        // when {ec} is present, it must be the last component
        if count[TemplateComponent.eanChecksum.key] != nil, let comp = components.last {
            if comp.key != TemplateComponent.eanChecksum.key {
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
            let regex = try NSRegularExpression(pattern: regexStr, options: [.dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: text.count)
            let matches = regex.matches(in: text, options: [], range: range)
            if let match = matches.first {
                var result = [String]()
                for range in 1 ..< match.numberOfRanges {
                    if let range = Range(match.range(at: range), in: text) {
                        let str = String(text[range])
                        result.append(str)
                    }
                }
                return result
            }
        } catch {
            Log.error("\(error)")
        }
        return []
    }
}

extension CodeTemplate {
    public static let defaultName = "default"
}

/// the matcher's result
public struct ParseResult: Sendable {
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
        return ""
    }

    /// is this result valid?
    /// (it is if all components are valid)
    public var isValid: Bool {
        for component in entries where !valid(component) {
            return false
        }
        return true
    }

    public var referencePrice: Int? {
        guard
            let entry = self.entries.first(where: { $0.templateComponent.isPrice }),
            let value = Int(entry.value)
        else {
            return nil
        }

        return value
    }

    public var embeddedData: Int? {
        guard
            let entry = self.entries.first(where: { $0.templateComponent.isEmbed }),
            let value = Int(entry.value)
        else {
            return nil
        }

        if case .embed100 = entry.templateComponent {
            return value * 100
        }
        return value
    }

    public var embeddedDecimal: EmbeddedDecimal? {
        guard
            let entry = self.entries.first(where: { $0.templateComponent.isDecimal }),
            case .embedDecimal(let intDigits, let fractionDigits) = entry.templateComponent,
            let value = Int(entry.value)
        else {
            return nil
        }

        return EmbeddedDecimal(integerDigits: intDigits, fractionDigits: fractionDigits, value: value)
    }

    /// embed data into a scanned code in place of the `embed` placeholder
    public func embed(_ data: Int) -> String {
        var result = ""
        var embeddedData = ""
        var internalChecksum = false
        var eanChecksum = false
        for entry in self.entries {
            switch entry.templateComponent {
            case .embed:
                let str = String(data)
                let padding = String(repeatElement("0", count: entry.templateComponent.length - str.count))
                embeddedData = padding + str
                result.append(embeddedData)
            case .internalChecksum:
                internalChecksum = true
                result.append(entry.value)
            case .eanChecksum:
                eanChecksum = true
                result.append(entry.value)
            default:
                result.append(entry.value)
            }
        }

        // calculate EAN-13 checksum(s)
        if internalChecksum {
            let embedDigits = embeddedData.map { Int(String($0))! }
            let check = EAN13.internalChecksum5(embedDigits)
            result = String(result.prefix(6)) + String(check) + String(result.suffix(6))
        }
        if eanChecksum, let ean = EAN13(String(result.prefix(12))) {
            return ean.code
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
            case .matchAll:
                return true
            case .matchConstant(let constant):
                return entry.value == constant
            }
        case .internalChecksum:
            guard let embedComponent = self.entries.first(where: { $0.templateComponent.isEmbed }) else {
                return false
            }
            let digits = embedComponent.value.compactMap { Int(String($0)) }
            let checksum = EAN13.internalChecksum5(digits)
            return String(checksum) == entry.value
        case .eanChecksum:
            let str = self.entries.map { $0.value }.joined()
            if let ean = EAN.parse(str) {
                return ean.checkDigit == Int(entry.value)!
            } else {
                return false
            }
        default:
            return true
        }
    }
}

public struct OverrideLookup: Sendable {
    public let lookupCode: String
    public let lookupTemplate: String?
    public let transmissionCode: String?
    public let embeddedData: Int?
}

public enum CodeMatcher {
    nonisolated(unsafe) private static var templates = [Identifier<Project>: [String: CodeTemplate]]()

    static func addTemplate(_ projectId: Identifier<Project>, _ id: String, _ template: String) {
        // print("add template \(projectId) \(id) \(template)")
        guard let tmpl = CodeTemplate(id, template) else {
            Log.warn("ignoring invalid template: \(id) \(template) for \(projectId)")
            return
        }

        CodeMatcher.templates[projectId, default: [:]][id] = tmpl
    }

    // only for unit tests!
    static func clearTemplates() {
        CodeMatcher.templates = [:]
    }

    public static func match(_ code: String, _ projectId: Identifier<Project>) -> [ParseResult] {
        guard let templates = CodeMatcher.templates[projectId] else {
            return []
        }

        let results: [ParseResult] = templates.values.reduce(into: [], { result, template in
            if let res = template.match(code) {
                result.append(res)
            }
        })

        return results
    }

    public static func matchOverride(_ code: String, _ overrides: [PriceOverrideCode]?, _ projectId: Identifier<Project>) -> OverrideLookup? {
        guard let overrides = overrides, !overrides.isEmpty else {
            return nil
        }

        guard let candidates = CodeMatcher.templates[projectId] else {
            return nil
        }

        let templates = overrides.compactMap { candidates[$0.id] }
        guard
            let result = templates.compactMap({ $0.match(code) }).first,
            let overrideCode = overrides.first(where: { $0.id == result.template.id })
        else {
            return nil
        }

        let lookupCode = result.lookupCode
        let lookupTemplate = overrideCode.lookupTemplate
        if let transmissionTemplate = overrideCode.transmissionTemplate {
            if let transmissionCode = overrideCode.transmissionCode, let embeddedData = result.embeddedData {
                let newCode = createInstoreEan(transmissionTemplate, transmissionCode, embeddedData, projectId)
                return OverrideLookup(lookupCode: lookupCode, lookupTemplate: lookupTemplate, transmissionCode: newCode, embeddedData: embeddedData)
            } else {
                return OverrideLookup(lookupCode: lookupCode, lookupTemplate: lookupTemplate, transmissionCode: overrideCode.transmissionCode, embeddedData: result.embeddedData)
            }
        } else {
            return OverrideLookup(lookupCode: lookupCode, lookupTemplate: lookupTemplate, transmissionCode: overrideCode.transmissionCode, embeddedData: result.embeddedData)
        }
    }

    public static func createInstoreEan(_ templateId: String, _ code: String, _ data: Int, _ projectId: Identifier<Project>? = nil) -> String? {
        guard let template = self.findTemplate(templateId, projectId) else {
            return nil
        }

        let rawEmbed = String(data)
        let padding = String(repeating: "0", count: 5 - rawEmbed.count)
        let embed = padding + rawEmbed

        var result = ""
        var embedSeen = false
        for component in template.components {
            switch component {
            case .plainText(let str):
                result.append(str)
            case .code(let type):
                if code.count != type.length {
                    return nil
                }
                result.append(code)
            case .internalChecksum:
                let embedDigits = embed.map { Int(String($0))! }
                let check = EAN13.internalChecksum5(embedDigits)
                result.append(String(check))
            case .embed(let len):
                result.append(String(repeating: "0", count: len))
                embedSeen = true
            case .ignore(let ignoreLength):
                if case .length(let len) = ignoreLength {
                    result.append(String(repeating: "0", count: len))
                }
            default: ()
            }
        }

        if !embedSeen {
            return nil
        }

        let ean = EAN13(String(result.prefix(7)) + embed)
        return ean?.code
    }

    private static func findTemplate(_ templateId: String, _ projectId: Identifier<Project>?) -> CodeTemplate? {
        if let projectId = projectId {
            return CodeMatcher.templates[projectId]?[templateId]
        } else {
            let matching = CodeMatcher.templates.values.flatMap { $0 }.filter { $0.key == templateId }
            return matching.first?.value
        }
    }
}
