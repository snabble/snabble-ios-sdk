//
//  ArchiveListScreen.swift
//
//  Created by Uwe Tilemann on 25.06.26.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents

/// Shows the locally archived receipts loaded from the `.index.json` manifest.
public struct ArchiveListScreen: View {

    @State private var viewModel = PurchasesViewModel()

    public init() {}

    public var body: some View {
        AsyncContentView(source: viewModel, content: { output in
            List(output, id: \.id) { provider in
                let pdfURL = OrderArchiveManager.archivedReceiptURL(for: provider as! Order)
                if FileManager.default.fileExists(atPath: pdfURL.path) {
                    NavigationLink {
                        ReceiptDetailScreen(localURL: pdfURL, provider: provider)
                    } label: {
                        ReceiptsItemView(
                            provider: provider,
                            image: viewModel.imageFor(projectId: provider.projectId),
                            showReadState: !viewModel.isRead(receiptId: provider.id),
                            showChevron: false
                        )
                    }
                    .onAppear {
                        viewModel.markAsRead(receiptId: provider.id)
                    }
                } else {
                    ReceiptsItemView(
                        provider: provider,
                        image: viewModel.imageFor(projectId: provider.projectId),
                        showReadState: false,
                        showChevron: false
                    )
                }
            }
            .listStyle(.plain)
        }, empty: {
            ContentUnavailableView(
                Asset.localizedString(forKey: "Snabble.Receipts.noReceipts"),
                systemImage: "archivebox"
            )
        })
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Receipts.Archive.listTitle"))
        .task {
            viewModel.loadFromArchive()
        }
    }
}
