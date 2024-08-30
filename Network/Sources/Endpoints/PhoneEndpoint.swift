//
//  PhoneEndpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-03.
//

import Foundation

extension Endpoints {
    public enum Phone {
        public static func auth(phoneNumber: String) -> Endpoint<Void> {
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "phoneNumber": phoneNumber
            ])
            return .init(
                path: "/apps/users/me/verification/phone-number",
                method: .post(data),
                parse: { _ in
                    return ()
                }
            )
        }

        public static func signIn(phoneNumber: String, OTP: String) -> Endpoint<SnabbleNetwork.AppUserDTO?> {
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "otp": OTP,
                "phoneNumber": phoneNumber,
                "intention": "sign-in"
            ])
            return .init(
                path: "/apps/users/me/verification/phone-number/otp",
                method: .post(data),
                parse: { data in
                    do {
                        return try Endpoints.jsonDecoder.decode(SnabbleNetwork.AppUserDTO.self, from: data)
                    } catch {
                        if case DecodingError.keyNotFound(let codingKey, _) = error {
                            if codingKey.stringValue == "secret" {
                                return nil
                            }
                        }
                        if data.isEmpty {
                            return nil
                        }
                        throw error
                    }
                })
        }
        
        public static func changePhoneNumber(phoneNumber: String, OTP: String) -> Endpoint<SnabbleNetwork.AppUserDTO?> {
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: [
                "otp": OTP,
                "phoneNumber": phoneNumber,
                "intention": "change-phone-number"
            ])
            return .init(
                path: "/apps/users/me/verification/phone-number/otp",
                method: .post(data),
                parse: { data in
                    do {
                        return try Endpoints.jsonDecoder.decode(SnabbleNetwork.AppUserDTO.self, from: data)
                    } catch {
                        if case DecodingError.keyNotFound(let codingKey, _) = error {
                            if codingKey.stringValue == "secret" {
                                return nil
                            }
                        }
                        if data.isEmpty {
                            return nil
                        }
                        throw error
                    }
                })
        }

        public static func delete() -> Endpoint<Void> {
            return .init(
                path: "/apps/users/me/phone-number",
                method: .delete,
                parse: { _ in
                    return ()
                }
            )
        }
    }
}
