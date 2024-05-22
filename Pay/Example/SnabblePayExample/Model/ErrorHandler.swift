//
//  ErrorHandler.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 01.03.23.
//

import Foundation
import SnabblePay
import Combine

struct ErrorInfo: Identifiable, Equatable {
    let id = UUID()

    static func == (lhs: ErrorInfo, rhs: ErrorInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    let error: SnabblePay.Error
    let action: String
    
    var localizedReason: String {
        if case .transportError(let urlError) = error {
            return urlError.localizedDescription
        }
        return error.localizedDescription
    }
    var localizedAction: String {
        let format = NSLocalizedString("Error for action", comment: "" )
        return String.localizedStringWithFormat(format, NSLocalizedString(action, comment: ""))
    }
    var localizedMessage: String {
        return localizedAction + "\n\n" + localizedReason
    }
}

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var error: ErrorInfo?
}
