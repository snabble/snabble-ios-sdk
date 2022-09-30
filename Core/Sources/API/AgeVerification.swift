//
//  AgeVerification.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

enum AgeVerification {
    enum SettingsKeys {
        static let usersBirthday = "usersBirthday" // string in the format YYMMDD
    }
}

extension AgeVerification {
    static let formatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.dateFormat = "yyMMdd"
        fmt.timeZone = TimeZone(identifier: "UTC")


        
        return fmt
    }()

    static func setUsersBirthday(_ birthdate: String?) {
        guard let birthdate = birthdate else {
            UserDefaults.standard.removeObject(forKey: AgeVerification.SettingsKeys.usersBirthday)
            return
        }

        guard self.formatter.date(from: birthdate) != nil else {
            return
        }

        UserDefaults.standard.set(birthdate, forKey: AgeVerification.SettingsKeys.usersBirthday)
    }

    static func getUsersBirthday() -> Date? {
        guard let birthdate = UserDefaults.standard.string(forKey: AgeVerification.SettingsKeys.usersBirthday) else {
            return nil
        }

        return self.formatter.date(from: birthdate)
    }

    // in years
    static func getUsersAge() -> Int? {
        guard let birthdate = Self.getUsersBirthday() else {
            return nil
        }

        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let components = calendar.dateComponents([.year], from: birthdate, to: today)
        return components.year
    }
}
