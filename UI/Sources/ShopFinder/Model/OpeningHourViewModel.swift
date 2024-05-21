//
//  OpeningHourViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 25.08.22.
//

import Foundation
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

public protocol OpeningHourProvider {
    var day: String? { get }
    var hour: String? { get }
}

extension DateFormatter {
    var usesAMPM: Bool {
        return DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: NSLocale.current)?.contains("a") ?? false
    }
}

extension String {
    var dateFromServerTime: Date? {
        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "HH:mm"

        return formatter.date(from: self)
    }
}

extension Date {
    var localTimeString: String? {
        let formatter = DateFormatter()

        formatter.dateFormat = formatter.usesAMPM ? "hh:mm aa" : "HH:mm"

        return formatter.string(from: self)
    }
}

struct TimeRange: CustomStringConvertible {
    let start: String?
    let end: String?
    let startDate: Date?
    let endDate: Date?

    init(start: String?, end: String?) {
        self.start = start
        self.end = end
        self.startDate = start?.dateFromServerTime
        self.endDate = end?.dateFromServerTime
    }

    var startString: String? {
        return self.startDate?.localTimeString ?? self.start
    }

    var endString: String? {
        return self.endDate?.localTimeString ?? self.end
    }

    var description: String {
        let start = startString
        let end = endString
        
        if let start = start, let end = end {
            return start + " – " + end
        } else if let start = start {
            return Asset.localizedString(forKey: "Snabble.Shop.Detail.startTime") + " " + start    // "ab"
        } else if let end = end {
            return Asset.localizedString(forKey: "Snabble.Shop.Detail.endTime") + " " + end // "bis"
        }
        return ""
    }
}

extension String {
    var localDayOfWeek: String {
        var calendar = Calendar(identifier: .gregorian)
        
        calendar.locale = NSLocale(localeIdentifier: "en_GB") as Locale
        
        guard let index = calendar.weekdaySymbols.firstIndex(of: self) else {
            return self
        }
        calendar.locale = Locale(identifier: Locale.preferredLanguages[0])
        return calendar.weekdaySymbols[index]
    }
}

public struct OpeningHourViewModel: Swift.Identifiable, OpeningHourProvider {
    public var id = UUID()
    public let day: String?
    public let hour: String?

    init(forWeekday weekday: String, withSpecification specification: [OpeningHoursSpecification]) {
        let filteredSpecification = specification.filter { $0.dayOfWeek == weekday }
        if let dayKey = filteredSpecification.first?.dayOfWeek {
            self.day = dayKey.localDayOfWeek
        } else {
            self.day = nil
        }
        
        self.hour = filteredSpecification
            .sorted(by: { $0.opens.prefix(2) < $1.opens.prefix(2) })
            .map { TimeRange(start: String($0.opens.prefix(5)), end: String($0.closes.prefix(5))).description }
            .joined(separator: "\n")
    }
}
