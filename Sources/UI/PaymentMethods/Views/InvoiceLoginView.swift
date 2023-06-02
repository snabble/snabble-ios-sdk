//
//  InvoiceLoginView.swift
//  
//
//  Created by Uwe Tilemann on 02.06.23.
//

import Foundation
import SwiftUI

public struct InvoiceLoginView: View {
    @ObservedObject var model: InvoiceLoginProcessor

    public init(model: InvoiceLoginProcessor) {
        self.model = model
    }

    public var body: some View {
        Form {
            
        }
    }
}
