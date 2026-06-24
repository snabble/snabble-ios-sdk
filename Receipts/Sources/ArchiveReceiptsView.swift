//
//  ArchiveReceiptsView.swift
//
//  Copyright © 2026 snabble. All rights reserved.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents
import SnabbleAssetProviding

/// A self-contained sheet view that downloads all available receipts into a
/// dated archive folder and reports download progress.
///
/// Present it as a sheet and pass `orders` + `project`:
/// ```swift
/// .sheet(isPresented: $showArchive) {
///     ArchiveReceiptsView(orders: orders, project: project)
/// }
/// ```
public struct ArchiveReceiptsView: View {

    private let orders: [Order]
    private let silent: Bool
    
    @State private var viewModel = ArchiveReceiptsViewModel()
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    public init(orders: [Order], silent: Bool = false) {
        self.orders = orders
        self.silent = silent
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(Asset.localizedString(forKey: "Snabble.Receipts.Archive.title")) // Archive Receipts
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .task { if silent {
                    viewModel.startArchive(orders: orders)
                }}
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            if silent {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                idleView()
            }
            
        case .archiving(let progress):
            archivingView(progress: progress)

        case .done(let url):
            doneView(url: url)

        case .failed(let error):
            failedView(error: error)
        }
    }

    private func idleView() -> some View {
        VStack(spacing: 20) {
            Text(Asset.localizedString(forKey: "Snabble.Receipts.Archive.start")) // "Archive your Receipts"
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                SecondaryButtonView(title: Asset.localizedString(forKey: "Snabble.cancel")) { dismiss() }
                PrimaryButtonView(title: Asset.localizedString(forKey: "Snabble.Receipts.Archive.create")) { viewModel.startArchive(orders: orders) } // "Create Archive"
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func archivingView(progress: ArchiveProgress) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: progress.fraction) {
                Text("\(progress.completed) of \(progress.total) receipts")
                    .font(.subheadline)
            }
            .progressViewStyle(.linear)
            .padding(.horizontal)

            if !progress.currentShopName.isEmpty {
                Text(progress.currentShopName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let orderDate = progress.currentOrderDate {
                    Text(orderDate.formatted(.dateTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func doneView(url: URL) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text(Asset.localizedString(forKey: "Snabble.Receipts.Archive.created")) // "Archive Created"
                .font(.title2.bold())
            Text(Asset.localizedString(forKey: "Snabble.Receipts.Archive.ordersArchived", arguments: orders.count)) // \(orders.count) order(s) archived.
            
            if !silent {
                Button {
                    showShareSheet = true
                } label: {
                    Label(Asset.localizedString(forKey: "Snabble.Receipts.Archive.share"), systemImage: "square.and.arrow.up") // "Share Archive"
                }
                .buttonStyle(ProjectPrimaryButtonStyle())
                .sheet(isPresented: $showShareSheet) {
                    ArchiveShareSheet(url: url)
                }
            }
        }
        .task {
            if silent {
                try? await Task.sleep(for: .seconds(1))
                dismiss()
            }
        }
#if DEBUG
        .task {
            print("archived url: \(url)")
        }
#endif
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failedView(error: Error) -> some View {
        VStack(spacing: 24) {
            ContentUnavailableView(
                Asset.localizedString(forKey: "Snabble.Receipts.Archive.failed"), // "Archive Failed"
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription)
            )

            Button {
                viewModel.startArchive(orders: orders)
            } label: {
                Label(Asset.localizedString(forKey: "Snabble.Receipts.Archive.retry"), systemImage: "arrow.clockwise") // "Try Again"
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
   }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if case .archiving = viewModel.state {
                Button(Asset.localizedString(forKey: "Snabble.cancel")) {
                    viewModel.cancel()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - UIActivityViewController wrapper for directory sharing

private struct ArchiveShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
