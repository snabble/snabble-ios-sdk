//
//  OpeningHoursViewModel.swift
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

struct OpeningHourViewModel: OpeningHourProvider {
    let day: String?
    let hour: String?

    init(forWeekday weekday: String, withSpecification specification: [OpeningHoursSpecification]) {
        let filteredSpecification = specification.filter { $0.dayOfWeek == weekday }
        if let dayKey = filteredSpecification.first?.dayOfWeek/*.lowercased()*/ {
            self.day = Asset.localizedString(forKey: dayKey) + ":"
        } else {
            self.day = nil
        }
        self.hour = filteredSpecification.map { "\($0.opens.prefix(5)) – \($0.closes.prefix(5))" }.joined(separator: "\n")
    }
}
