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

    var isAllDay: Bool {
        start == "00:00" && (end == "23:59" || end == "24:00")
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



    init(day: String?, hour: String?) {
        self.day = day
        self.hour = hour
    }

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

fileprivate struct DayEntry {
    let localizedDay: String
    let hourString: String
    let isAllDay: Bool
}

fileprivate struct DayGroup {
    var firstDay: String
    var lastDay: String?
    var hourString: String
    var isAllDay: Bool
    var count: Int
    
    init(firstDay: String, lastDay: String? = nil, hourString: String, isAllDay: Bool, count: Int) {
        self.firstDay = firstDay
        self.lastDay = lastDay
        self.hourString = hourString
        self.isAllDay = isAllDay
        self.count = count
    }
}

public extension ShopProviding {
    var openingHoursViewModel: [OpeningHourViewModel] {
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        let entries: [DayEntry] = weekdays.compactMap { weekday in
            let specs = openingHoursSpecification.filter { $0.dayOfWeek == weekday }
            guard !specs.isEmpty else { return nil }
            var seen = Set<String>()
            let ranges = specs
                .sorted { $0.opens.prefix(2) < $1.opens.prefix(2) }
                .compactMap { spec -> TimeRange? in
                    let key = "\(spec.opens)-\(spec.closes)"
                    guard seen.insert(key).inserted else { return nil }
                    return TimeRange(start: String(spec.opens.prefix(5)), end: String(spec.closes.prefix(5)))
                }
            let localized = weekday.localDayOfWeek
            return DayEntry(
                localizedDay: localized.isEmpty ? weekday : localized,
                hourString: ranges.map(\.description).joined(separator: "\n"),
                isAllDay: ranges.count == 1 && ranges[0].isAllDay
            )
        }

        var groups: [DayGroup] = []
        for entry in entries {
            if !groups.isEmpty && groups[groups.count - 1].hourString == entry.hourString {
                groups[groups.count - 1].lastDay = entry.localizedDay
                groups[groups.count - 1].count += 1
            } else {
                groups.append(DayGroup(
                    firstDay: entry.localizedDay,
                    lastDay: nil,
                    hourString: entry.hourString,
                    isAllDay: entry.isAllDay,
                    count: 1
                ))
            }
        }

        if groups.count == 1 && groups[0].count == 7 && groups[0].isAllDay {
            return [OpeningHourViewModel(day: "24/7", hour: nil)]
        }

        return groups.map { group in
            let dayLabel: String
            if let last = group.lastDay {
                dayLabel = "\(group.firstDay) – \(last)"
            } else {
                dayLabel = group.firstDay
            }
            let hourLabel = group.isAllDay
                ? Asset.localizedString(forKey: "Snabble.Shop.Detail.allDay")
                : group.hourString
            return OpeningHourViewModel(day: dayLabel.isEmpty ? nil : dayLabel, hour: hourLabel)
        }
    }
}
