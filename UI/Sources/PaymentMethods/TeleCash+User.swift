//
//  TeleCash+User.swift
//  
//
//  Created by Uwe Tilemann on 08.08.24.
//

import SnabbleCore
import SnabbleUser

extension TeleCashCreditCardAddViewController: UserFieldProviding {
    public static var defaultUserFields: [UserField] {
        UserField.allCases.fieldsWithout([.state, .dateOfBirth])
    }
    public static var requiredUserFields: [UserField] {
        UserField.allCases.fieldsWithout([.state, .dateOfBirth])
    }
}

struct TeleCashUser: Codable {
    let name: String?
    let email: String?
    let phoneNumber: String?
    let address: Address?
    
    public struct Address: Codable {
        public var street: String?
        public var zip: String?
        public var city: String?
        public var country: String?
        public var state: String?
    }
}

extension TeleCashUser {
    static func user(from user: SnabbleUser.User) -> TeleCashUser {
        let address = TeleCashUser.Address(street: user.street,
                                           zip: user.zip,
                                           city: user.city,
                                           country: user.country,
                                           state: user.state)
        return TeleCashUser(name: user.fullName,
                                 email: user.email,
                                 phoneNumber: user.phoneNumber,
                                 address: address)
    }
}

extension TeleCashCreditCardAddViewController: UserValidation {
    public func acceptUser(user: SnabbleUser.User) -> Bool {
        // Simple validation here, as all required fields are filled in the form.
        guard let firstName = user.firstName, !firstName.isEmpty else {
            return false
        }
        self.user = TeleCashUser.user(from: user)
        return true
    }
}
