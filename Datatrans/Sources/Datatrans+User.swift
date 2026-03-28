//
//  Datatrans+User.swift
//
//
//  Created by Uwe Tilemann on 08.08.24.
//

import Foundation
import UIKit

import SnabbleAssetProviding
import SnabbleUser
import SnabbleTheme
struct DatatransUser: Codable {
    let name: String?
    let email: String?
    let phoneNumber: Phone?
    let address: Address?
    
    struct Phone: Codable {
        let countryCode: String?
        let subscriber: String?
    }
    public struct Address: Codable {
        let street: String?
        let zip: String?
        let city: String?
        let country: String?
        let state: String?
    }
}

extension SnabbleUser.User {
    var countryNumber: String? {
        let number: String?
        if let countryCode = address?.country,
            let country = Country.all.country(forCode: countryCode),
            let numeric = country.numeric {
            number = String(numeric)
        } else {
            number = nil
        }
        return number
    }
}

extension DatatransAliasViewController: UserFieldProviding {
    nonisolated public static var defaultUserFields: [SnabbleUser.UserField] {
        UserField.fieldsWithout([.state, .dateOfBirth])
    }
    
    nonisolated public static var requiredUserFields: [SnabbleUser.UserField] {
        UserField.fieldsWithout([.state, .dateOfBirth])
    }
}

extension DatatransAliasViewController: UserValidation {
    public func acceptUser(user: SnabbleUser.User) -> Bool {
        // Simple validation here, as all required fields are filled in the form.
        guard let firstName = user.firstName, !firstName.isEmpty else {
            return false
        }
        self.user = DatatransUser.user(from: user)

        return true
    }
}

extension DatatransUser {
    static func user(from user: SnabbleUser.User) -> DatatransUser {
        let address = DatatransUser.Address(street: user.address?.street,
                                            zip: user.address?.zip,
                                            city: user.address?.city,
                                            country: user.countryNumber,
                                            state: user.address?.state)
        
        let phone: DatatransUser.Phone?
        
        if let code = user.phone?.code {
            phone = DatatransUser.Phone(countryCode: String(code), subscriber: user.phone?.number)
        } else {
            phone = nil
        }
        return DatatransUser(name: user.fullName,
                             email: user.email,
                             phoneNumber: phone,
                             address: address)
    }
}
