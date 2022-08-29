//
//  OpeningHourViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 25.08.22.
//

import Foundation
import SwiftUI

public protocol OpeningHourProvider {
    var day: String? { get }
    var hour: String? { get }
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
            .map { "\($0.opens.prefix(5)) – \($0.closes.prefix(5))" }
            .joined(separator: "\n")
    }
}
