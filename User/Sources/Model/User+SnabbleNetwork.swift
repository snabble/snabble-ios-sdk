//
//  User+SnabbleNetwork.swift
//
//
//  Created by Andreas Osberghaus on 2024-08-30.
//

import Foundation
import SnabbleNetwork

extension SnabbleNetwork.User {
    public init(user: SnabbleNetwork.User, details: SnabbleNetwork.User.Details) {
        self.init(
            id: user.id,
            phoneNumber: user.phoneNumber,
            details: details,
            fields: user.fields,
            consent: user.consent
        )
    }
    
    public init(user: SnabbleNetwork.User, consent: SnabbleNetwork.User.Consent) {
        self.init(
            id: user.id,
            phoneNumber: user.phoneNumber,
            details: user.details,
            fields: user.fields,
            consent: consent
        )
    }
    
    public init(user: SnabbleUser.User) {
        self.init(
            id: user.id,
            phoneNumber: user.metadata?.phoneNumber,
            details: user.toNetworkDetails(),
            fields: user.toNetworkFields(),
            consent: user.toNetworkConsent()
        )
    }
}

public extension SnabbleUser.User {
    init(user: SnabbleNetwork.User) {
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

private extension Array where Element == SnabbleNetwork.User.Field {
    func toSnabbleField() -> [SnabbleUser.User.Field] {
        map { SnabbleUser.User.Field(field: $0) }
    }
}

private extension SnabbleUser.User {
    func toNetworkDetails() -> SnabbleNetwork.User.Details {
        return SnabbleNetwork.User.Details(
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
    
    func toNetworkFields() -> [SnabbleNetwork.User.Field]? {
        metadata?.fields?.map { .init(id: $0.id, isRequired: $0.isRequired) }
    }
    
    func toNetworkConsent() -> SnabbleNetwork.User.Consent? {
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

extension SnabbleUser.User.Consent {
    init?(consent: SnabbleNetwork.User.Consent?) {
        guard let consent else { return nil }
        self.init(major: consent.major, minor: consent.minor)
    }
}

extension SnabbleNetwork.User.Consent {
    init?(consent: SnabbleUser.User.Consent?) {
        guard let consent else { return nil }
        self.init(major: consent.major, minor: consent.minor)
    }
}

extension SnabbleNetwork.User.Field {
    init(field: SnabbleUser.User.Field) {
        self.init(id: field.id, isRequired: field.isRequired)
    }
}

extension SnabbleNetwork.User.Consent {
    init(consent: SnabbleUser.User.Consent) {
        self.init(major: consent.major, minor: consent.minor)
    }
}

extension SnabbleUser.User.Field {
    init(field: SnabbleNetwork.User.Field) {
        self.init(id: field.id, isRequired: field.isRequired)
    }
}

extension SnabbleUser.User.Consent {
    init(consent: SnabbleNetwork.User.Consent) {
        self.init(major: consent.major, minor: consent.minor)
    }
}
