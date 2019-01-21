//
//  CodeTemplates.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

// template parsing and matching, see
// https://github.com/snabble/product-ng/blob/master/code-templates.md

enum TemplateComponent {
    case plainText(String)
    case code(String)
    case weight(Int)
    case price(Int)
    case ignore(Int)
    case internalChecksum

    static let knownCodes = ["ean8": 8, "ean13": 13, "ean14": 14]

    init?(_ str: String) {
        if str.prefix(1) == "{" {
            let parts = str.dropFirst().dropLast().components(separatedBy: ":")
            let lengthPart = parts.count > 1 ? parts[1] : "1"
            let length = Int(lengthPart)

            if parts[0] == "code" {
                if TemplateComponent.knownCodes.keys.contains(lengthPart) || length != nil {
                    self = .code(lengthPart)
                } else {
                    return nil
                }
            } else {
                guard let len = length else {
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

    var regex: String {
        switch self {
        case .plainText(let str): return "(\\Q\(str)\\E)"
        case .code(let str): return "(\\d{\(self.codeLength(str))})"
        case .weight(let len): return "(\\d{\(len)})"
        case .price(let len): return "(\\d{\(len)})"
        case .ignore(let len): return "(.{\(len)})"
        case .internalChecksum: return "(\\d)"
        }
    }

    var length: Int {
        switch self {
        case .plainText(let str): return str.count
        case .code(let str): return self.codeLength(str)
        case .weight(let len): return len
        case .price(let len): return len
        case .ignore(let len): return len
        case .internalChecksum: return 1
        }
    }

    var isCode: Bool {
        switch self {
        case .code: return true
        default: return false
        }
    }

    var isWeight: Bool {
        switch self {
        case .weight: return true
        default: return false
        }
    }

    var key: Int {
        switch self {
        case .plainText: return 0
        case .code: return 1
        case .weight: return 2
        case .price: return 3
        case .ignore: return 4
        case .internalChecksum: return 5
        }
    }

    private func codeLength(_ str: String) -> Int {
        if let len = TemplateComponent.knownCodes[str] {
            return len
        } else {
            return Int(str) ?? 1
        }
    }
}

struct CodeTemplate {
    let template: String
    let components: [TemplateComponent]

    static let token = try! NSRegularExpression(pattern: "^(\\{.*?\\})", options: [])
    static let plaintext = try! NSRegularExpression(pattern: "^([^{]+)", options: [])
    static let regexps = [ token, plaintext ]

    var expectedLength: Int {
        return components.reduce(0) { $0 + $1.length }
    }

    init?(_ template: String) {
        var str = template

        var components = [TemplateComponent]()
        while str.count > 0 {
            var foundMatch = false
            for re in CodeTemplate.regexps {
                let result = re.matches(in: str, options: [], range: NSRange(location: 0, length: str.count))
                if result.count == 0 {
                    continue
                }
                foundMatch = true
                let range = result[0].range(at: 0)
                let token = String(str.prefix(range.length))
                if let component = TemplateComponent(token) {
                    components.append(component)
                } else {
                    return nil
                }
                str = String(str.dropFirst(range.length))
                continue
            }
            if !foundMatch {
                return nil
            }
        }

        self.components = components
        self.template = template

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
            if let weightComponent = components.first(where: { $0.isWeight }) {
                if weightComponent.length != 5 {
                    return nil
                }
            } else {
                return nil
            }
        }

    }

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

struct ParsedComponent {
    let template: TemplateComponent
    let value: String
}

struct ParseResult {
    let components: [ParsedComponent]

    var lookupCode: String {
        guard let codeComponent = self.components.first(where: { $0.template.isCode }) else {
            return ""
        }

        return codeComponent.value
    }

    var isValid: Bool {
        for comp in self.components {
            if !self.valid(comp) {
                return false
            }
        }
        return true
    }

    private func valid(_ component: ParsedComponent) -> Bool {
        switch component.template {
        case .code(let format):
            if TemplateComponent.knownCodes[format] != nil {
                return EAN.parse(component.value, nil) != nil
            } else {
                return component.value.count == Int(format)
            }
        case .internalChecksum:
            guard let weightComponent = self.components.first(where: { $0.template.isWeight }) else {
                return false
            }
            let digits = weightComponent.value.compactMap { Int(String($0)) }
            let checksum = EAN13.internalChecksum5(digits)
            return String(checksum) == component.value
        default: return true
        }
    }
}
