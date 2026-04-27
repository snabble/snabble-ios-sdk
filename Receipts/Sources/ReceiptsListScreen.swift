//
//  ReceiptsListScreen.swift
//
//
//  Created by Uwe Tilemann on 20.10.23.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
//import SnabbleTheme

/// Hashable wrapper for PurchaseProviding to enable navigation
public struct ReceiptNavigationItem: Hashable {
    public let orderId: String
    public let projectId: Identifier<SnabbleCore.Project>

    public init(provider: any PurchaseProviding) {
        self.orderId = provider.id
        self.projectId = provider.projectId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(orderId)
        hasher.combine(projectId)
    }

    public static func == (lhs: ReceiptNavigationItem, rhs: ReceiptNavigationItem) -> Bool {
        lhs.orderId == rhs.orderId && lhs.projectId == rhs.projectId
    }
}

public struct ReceiptsItemView: View {
    public let provider: any PurchaseProviding
    public let image: SwiftUI.Image
    public let showReadState: Bool
    public let showChevron: Bool

    public init(provider: any PurchaseProviding, image: SwiftUI.Image? = nil, showReadState: Bool = true, showChevron: Bool = true) {
        self.provider = provider
        self.image = image ?? Image(systemName: "scroll")
        self.showReadState = showReadState
        self.showChevron = showChevron
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
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

public struct ReceiptsListScreen<SomeEmptyView: View>: View {
    @State var viewModel: PurchasesViewModel
    @ViewProvider(.receiptsEmpty) var emptyView

    /// If true, provides built-in SwiftUI navigation to receipt detail.
    /// If false, uses the onAction callback for custom navigation handling.
    public let useBuiltInNavigation: Bool

    @ViewBuilder let placeholderView: SomeEmptyView
    
    public init(model: PurchasesViewModel = .init(), useBuiltInNavigation: Bool = true) {
        self._viewModel = State(initialValue: model)
        self.useBuiltInNavigation = useBuiltInNavigation
        self.placeholderView = EmptyView() as! SomeEmptyView
    }

    public init(model: PurchasesViewModel = .init(), useBuiltInNavigation: Bool = true, emptyView placeholder: SomeEmptyView) {
        self._viewModel = State(initialValue: model)
        self.useBuiltInNavigation = useBuiltInNavigation
        self.placeholderView = placeholder
    }

    public var body: some View {
        AsyncContentView(source: viewModel, content: { output in
            VStack {
                List {
                    ForEach(output, id: \.combinedID) { provider in
                        receiptRow(for: provider)
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
            Group {
                emptyView
                placeholderView
            }
        })
        .navigationDestination(for: ReceiptNavigationItem.self) { item in
            ReceiptDetailScreen(orderId: item.orderId, projectId: item.projectId)
                .onAppear {
                    viewModel.markAsRead(receiptId: item.orderId)
                }
        }
        .task {
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
                    Image(systemName: "ellipsis")
                }
            }
        }
        .badge(viewModel.numberOfUnread)
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Receipts.title"))

    }

    @ViewBuilder
    private func receiptRow(for provider: any PurchaseProviding) -> some View {
        if useBuiltInNavigation {
            NavigationLink(value: ReceiptNavigationItem(provider: provider)) {
                ReceiptsItemView(provider: provider, image: viewModel.imageFor(projectId: provider.projectId), showChevron: false)
            }
        } else {
            ReceiptsItemView(provider: provider, image: viewModel.imageFor(projectId: provider.projectId))
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.markAsRead(receiptId: provider.id)
                    viewModel.onAction?(provider)
                }
        }
    }
}

extension PurchaseProviding {
    var combinedID: String {
        return "\(id)_\(isRead ? "read" : "unread")"
    }
}
