//
//  User+UserDTO.swift
//
//
//  Created by Andreas Osberghaus on 2024-08-30.
//

import Foundation

extension SnabbleUser.User {
    static func fromDTO(_ user: UserDTO) -> Self {
        self.init(
            id: user.id,
            metadata: .init(
                phoneNumber: user.phoneNumber,
                fields: user.fields?.toSnabbleField(),
                consent: .init(consent: user.consent)),
            firstname: user.details?.firstName,
            lastname: user.details?.lastName,
            email: user.details?.email,
            phone: nil,
            dateOfBirth: user.details?.dateOfBirth?.toDate(),
            street: user.details?.street,
            zip: user.details?.zip,
            city: user.details?.city,
            country: user.details?.country,
            state: user.details?.state)
    }
}

private extension Array where Element == UserDTO.Field {
    func toSnabbleField() -> [SnabbleUser.User.Field] {
        map { SnabbleUser.User.Field(field: $0) }
    }
}

private extension SnabbleUser.User {
    func toDtoDetails() -> UserDTO.Details {
        return UserDTO.Details(
            firstName: firstname,
            lastName: lastname,
            email: email,
            dateOfBirth: dateOfBirth?.toString(),
            street: address?.street,
            zip: address?.zip,
            city: address?.city,
            country: address?.country,
            state: address?.state
        )
    }
    
    func toDtoFields() -> [UserDTO.Field]? {
        metadata?.fields?.map { .init(id: $0.id, isRequired: $0.isRequired) }
    }
    
    func toDtoConsent() -> UserDTO.Consent? {
        guard let consent = metadata?.consent else {
            return nil
        }
        return .init(major: consent.major, minor: consent.minor)
    }
    
}

private extension String {
    func toDate(withFormat format: String = "yyyy-MM-dd") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
}

private extension Date {
    func toString(withFormat format: String = "yyyy-MM-dd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

private extension SnabbleUser.User.Consent {
    init?(consent: UserDTO.Consent?) {
        guard let consent else { return nil }
        self.init(major: consent.major, minor: consent.minor)
    }
}

private extension UserDTO.Consent {
    init?(consent: SnabbleUser.User.Consent?) {
        guard let consent else { return nil }
        self.init(major: consent.major, minor: consent.minor)
    }
}

private extension UserDTO.Field {
    init(field: SnabbleUser.User.Field) {
        self.init(id: field.id, isRequired: field.isRequired)
    }
}

private extension UserDTO.Consent {
    init(consent: SnabbleUser.User.Consent) {
        self.init(major: consent.major, minor: consent.minor)
    }
}

private extension SnabbleUser.User.Field {
    init(field: UserDTO.Field) {
        self.init(id: field.id, isRequired: field.isRequired)
    }
}

private extension SnabbleUser.User.Consent {
    init(consent: UserDTO.Consent) {
        self.init(major: consent.major, minor: consent.minor)
    }
}
