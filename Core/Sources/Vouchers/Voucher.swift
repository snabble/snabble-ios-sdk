//
//  Voucher.swift
//  Snabble
//
//  Created by Uwe Tilemann on 03.12.24.
//

import Foundation

public enum VoucherType: String, Codable, UnknownCaseRepresentable {
    case unknown

    case depositReturn = "depositReturnVoucher"

    public static var unknownCase = VoucherType.unknown
}

public struct Voucher: Codable {
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
