//
//  Payment.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 08.09.23.
//

import SwiftUI
import OSLog

import SnabbleCore
import SnabbleUI

extension Payment: Equatable {
    public static func == (lhs: Payment, rhs: Payment) -> Bool {
        return lhs.id == rhs.id
    }
}
