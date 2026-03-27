//
//  AddressView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 23.08.22.
//

import Foundation
import SwiftUI

public struct AddressView: View {
    var provider: AddressProviding

    public var body: some View {
        Group {
            Text(provider.street)
            Text("\(provider.postalCode) \(provider.city)")
        }
    }
}

/// Protocol to provide address information
public protocol AddressProviding {
    var street: String { get }
    var postalCode: String { get }
    var city: String { get }
}
