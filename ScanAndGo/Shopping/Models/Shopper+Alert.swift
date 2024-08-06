//
//  Shopper+Alert.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleCore
import SnabbleUI

extension Shopper {
    func alert(_ controller: UIAlertController) -> Alert {
        if let message = controller.message {
            return Alert(title: Text(controller.title ?? "no title"),
                         message: Text(message)
            )
        } else {
            return Alert(title: Text(controller.title ?? "no title"))
        }
    }
}
