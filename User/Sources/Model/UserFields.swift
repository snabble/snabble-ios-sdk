//
//  UserFields.swift
//
//
//  Created by Uwe Tilemann on 02.08.24.
//
import SwiftUI

import SnabbleAssetProviding

public protocol UserFieldProviding {
    static var defaultUserFields: [UserField] { get }
    static var requiredUserFields: [UserField] { get }
}

public enum UserField: String, CaseIterable, Swift.Identifiable, Hashable {
    public var id: Self { self }
    
    case firstName
    case lastName
    case email
    case phone
    case dateOfBirth
    case street
    case zip
    case city
    case country
    case state
    
    public static var `default`: [Self] {
        Self.fieldsWithout([.state, .dateOfBirth])
    }
}

extension UserField {
    public var prompt: String {
        switch self {
        case .firstName:
            "Snabble.User.firstName"
        case .lastName:
            "Snabble.User.lastName"
        case .email:
            "Snabble.User.email"
        case .phone:
            "Snabble.User.phone"
        case .dateOfBirth:
            "Snabble.User.dateOfBirth"
        case .street:
            "Snabble.User.street"
        case .zip:
            "Snabble.User.zip"
        case .city:
            "Snabble.User.city"
        case .country:
            "Snabble.User.country"
        case .state:
            "Snabble.User.state"
        }
    }
    
    public var contentType: UITextContentType? {
        switch self {
        case .firstName:
                .givenName
        case .lastName:
                .familyName
        case .email:
                .emailAddress
        case .phone:
                .telephoneNumber
        case .dateOfBirth:
                .birthdateDay
        case .street:
                .streetAddressLine1
        case .zip:
                .postalCode
        case .city:
                .addressCity
        case .country:
                .countryName
        case .state:
                .addressState
        }
    }
    
    public var keyboardType: UIKeyboardType {
        switch self {
        case .firstName, .lastName, .dateOfBirth, .street, .city, .country, .state:
                .default
        case .email:
                .emailAddress
        case .phone:
                .phonePad
        case .zip:
                .numberPad
        }
    }
}

extension UserField {
    public static func fieldsWithout(_ unwanted: [UserField]) -> [UserField] {
        Self.allCases.fieldsWithout(unwanted)
    }
}

extension Array where Element == UserField {
    public func fieldsWithout(_ unwanted: [UserField]) -> [UserField] {
        self.filter { !unwanted.contains($0) }
    }
}
