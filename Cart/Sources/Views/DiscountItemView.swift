//
//  DiscountItemView.swift
//  
//
//  Created by Uwe Tilemann on 21.03.23.
//
import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleTheme

struct DiscountItemView: View {
    let amount: String
    var description: String?
    let showImages: Bool
    var onDelete: (() -> Void)?

    init(amount: Int, description: String? = nil, showImages: Bool = true, onDelete: (() -> Void)? = nil) {
        self.amount = PriceFormatter(SnabbleCI.project).format(amount)
        self.description = description
        self.showImages = showImages
        self.onDelete = onDelete
   }

    var body: some View {
        HStack {
            Text(amount)
                .cartPrice()
                .font(.footnote)

            Spacer()
            Text(description ?? "")
                .font(.footnote)
            Spacer()

            if let onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(Color.onProjectPrimary())
                }
                .buttonStyle(.plain)
            } else {
                Asset.image(named: "discount-badge")
                    .font(.title3)
                    .foregroundStyle(Color.onProjectPrimary())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .listRowBackground(Color.clear)
        .foregroundStyle(Color.onProjectPrimary())
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.projectPrimary())
        }
    }
}
