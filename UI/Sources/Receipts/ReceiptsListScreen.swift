//
//  ReceiptsListScreen.swift
//
//
//  Created by Uwe Tilemann on 20.10.23.
//

import SwiftUI
import Combine

import SnabbleCore
import SnabbleAssetProviding

public struct ReceiptsItemView: View {
    public let provider: PurchaseProviding
    public let image: SwiftUI.Image
    public let showReadState: Bool
    
    public init(provider: PurchaseProviding, image: SwiftUI.Image? = nil, showReadState: Bool = true) {
        self.provider = provider
        self.image = image ?? Image(systemName: "scroll")
        self.showReadState = showReadState
    }

    @ViewBuilder
    var stateView: some View {
        Circle()
            .fill((showReadState && !provider.isRead) ? Color.badge() : .clear)
            .frame(width: 10, height: 10)
    }

    public var body: some View {
        HStack {
            HStack {
                self.stateView
                self.image
                    .foregroundColor(.projectPrimary())
            }
            .frame(width: 60)
            VStack(alignment: .leading) {
                Text(provider.name)
                    .font(.headline)
                Text(provider.dateString ?? "")
                        .font(.footnote)
                        .foregroundColor(.secondary)
            }
            Spacer()
            if let amount = provider.amount {
                Text(amount)
                    .font(.footnote)
            }
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}

public struct ReceiptsListScreen: View {
    @State var viewModel: PurchasesViewModel
    @ViewProvider(.receiptsEmpty) var emptyView

    public init(model: PurchasesViewModel = .init()) {
        self._viewModel = State(initialValue: model)
    }

    public var body: some View {
        AsyncContentView(source: viewModel, content: { output in
            VStack {
                List {
                    ForEach(output, id: \.combinedID) { provider in
                        ReceiptsItemView(provider: provider, image: viewModel.imageFor(projectId: provider.projectId))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.markAsRead(receiptId: provider.id)
                                viewModel.actionPublisher.send(provider)
                            }
                            .contextMenu {
                                Button(action: {
                                    viewModel.markAllAsRead()
                                }) {
                                    Label(Asset.localizedString(forKey: "Snabble.Receipts.markAllAsRead"), systemImage: "envelope.open")
                                }
                                .disabled(viewModel.numberOfUnread == 0)
                                
                                Divider()

                                Button(action: {
                                    if provider.isRead {
                                        viewModel.markAsUnread(receiptId: provider.id)
                                    } else {
                                        viewModel.markAsRead(receiptId: provider.id)
                                    }
                                }) {
                                    Label(Asset.localizedString(forKey: provider.isRead ? "Snabble.Receipts.markAsUnread" : "Snabble.Receipts.markAsRead"),
                                          systemImage: provider.isRead ? "envelope.badge" : "envelope.badge.fill")
                                }
                            }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 16))
                }
                .id(viewModel.listRefreshTrigger)
                .listStyle(.plain)
                .refreshable {
                    viewModel.refresh()
                }
            }
        }, empty: {
            emptyView
        })
        .onAppear {
            viewModel.reset()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        viewModel.markAllAsRead()
                    }) {
                        Label(Asset.localizedString(forKey: "Snabble.Receipts.markAllAsRead"), systemImage: "envelope.open")
                    }
                    .disabled(viewModel.numberOfUnread == 0)
                } label: {
                    Image(systemName: "ellipsis.circle") // Standard "More" Icon
                }
            }
        }
        .badge(viewModel.numberOfUnread)
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Receipts.title"))

    }
}
extension PurchaseProviding {
    var combinedID: String {
        return "\(id)_\(isRead ? "read" : "unread")"
    }
}
