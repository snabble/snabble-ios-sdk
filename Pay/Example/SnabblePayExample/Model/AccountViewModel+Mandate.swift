//
//  AccountViewModel+Mandate.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 04.04.23.
//

import SwiftUI

extension AccountViewModel {
    var htmlText: String? {
        guard let mandateID = mandate?.id.rawValue,
              let html = UserDefaults.standard.object(forKey: mandateID) as? String else {
            return nil
        }
        return html
    }

    var markup: String? {
        guard let markup = htmlText,
              let body = markup.replacingOccurrences(of: "+", with: " ").removingPercentEncoding else {
            return nil
        }
        return body.htmlString()
    }
}

extension AccountViewModel {
    var mandateIDString: String {
        return mandate?.id.rawValue ?? ""
    }
    var mandateStateString: String {
        return NSLocalizedString(mandateState.rawValue, comment: "")
    }
    var mandateStateColor: Color {
        switch self.mandateState {
        case .missing, .pending:
            return Color.yellow
        case .accepted:
            return Color.green
        case .declined:
            return Color.red
        }
    }
    var mandateStateImage: Image {
        switch self.mandateState {
        case .missing, .pending:
            return Image(systemName: "questionmark.circle.fill")
        case .accepted:
            return Image(systemName: "checkmark.circle.fill")
        case .declined:
            return Image(systemName: "xmark.circle.fill")
        }
    }
}
