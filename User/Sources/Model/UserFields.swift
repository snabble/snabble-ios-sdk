//
//  UserFields.swift
//
//
//  Created by Uwe Tilemann on 02.08.24.
//
import SwiftUI

import SnabbleAssetProviding

public protocol UserFieldProviding {
    var defaultUserFields: [UserField] { get }
    var requiredUserFields: [UserField] { get }
}

public enum UserField: String, CaseIterable, Swift.Identifiable, Hashable {
    public var id: Self { self }
    
    case fullName
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
}

extension UserField {
    public static var fullNameFields: [UserField] { UserField.allCases.fieldsWithout([.firstName, .lastName]) }
    public static var defaultFields: [UserField] { UserField.allCases.fieldsWithout([.fullName]) }
}

extension UserField {
    public var prompt: String {
        switch self {
        case .fullName:
            "Snabble.User.fullName"
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
        case .fullName:
            return .name
        case .firstName:
            return .givenName
        case .lastName:
            return .familyName
        case .email:
            return .emailAddress
        case .phone:
            return .telephoneNumber
        case .dateOfBirth:
            if #available(iOS 17.0, *) {
                return .birthdateDay
            } else {
                return nil
            }
        case .street:
            return .streetAddressLine1
        case .zip:
            return .postalCode
        case .city:
            return .addressCity
        case .country:
            return .countryName
        case .state:
            return .addressState
        }
    }
    
    public var keyboardType: UIKeyboardType {
        switch self {
        case .fullName, .firstName, .lastName, .dateOfBirth, .street, .city, .country, .state:
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

extension Array where Element == UserField {
    public func fieldsWithout(_ unwanted: [UserField]) -> [UserField] {
        self.filter { !unwanted.contains($0) }
    }
}
