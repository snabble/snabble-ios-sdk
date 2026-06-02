//
//  Voucher.swift
//  Snabble
//
//  Created by Uwe Tilemann on 03.12.24.
//

import Foundation

public enum VoucherType: String, Codable, UnknownCaseRepresentable, Sendable {
    case unknown

    case depositReturn = "depositReturnVoucher"

    public static let unknownCase = VoucherType.unknown
}

public struct Voucher: Codable, Sendable {
    public let id: String

    public let itemID: String
    public let type: VoucherType
    public let scannedCode: String

    public init(id: String, itemID: String, type: VoucherType, scannedCode: String) {
        self.id = id
        self.itemID = itemID
        self.type = type
        self.scannedCode = scannedCode
    }
}
