//
//  ProjectPaymentEntryRow.swift
//
//
//  Created by Uwe Tilemann on 18.03.26.
//

import SwiftUI

import SnabbleAssets

struct ProjectPaymentEntryRow: View {
    let entry: PaymentMethodListManager.ProjectEntry
    @State private var storeIcon: UIImage?

    var body: some View {
        HStack(spacing: 16) {
            if let icon = storeIcon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            } else {
                Color.clear
                    .frame(width: 24, height: 24)
            }

            Text(entry.name)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(entry.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 30, alignment: .center)
        }
        .padding(.vertical, 4)
        .task {
            await loadStoreIcon()
        }
    }

    private func loadStoreIcon() async {
        await MainActor.run {
            SnabbleCI.getAsset(.storeIcon, projectId: entry.projectId) { image in
                Task { @MainActor in
                    storeIcon = image
                }
            }
        }
    }
}
