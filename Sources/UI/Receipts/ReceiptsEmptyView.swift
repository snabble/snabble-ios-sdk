//
//  ReceiptsEmptyView.swift
//  teo
//
//  Created by Uwe Tilemann on 10.04.24.
//

import SwiftUI
import SnabbleUI

struct ReceiptsEmptyView: View {
    var body: some View {
        let emptyString = Asset.localizedString(forKey: "Snabble.Receipts.noReceipts")

        if emptyString != "Snabble.Receipts.noReceipts" {
            VStack(spacing: 32) {
                if let image: SwiftUI.Image = Asset.image(named: "scroll", domain: nil) {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72)
                        .foregroundColor(.accentColor)
                }
                
                Text(emptyString)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding([.leading, .trailing], 48)
            }
            .padding()
        }
    }
}
