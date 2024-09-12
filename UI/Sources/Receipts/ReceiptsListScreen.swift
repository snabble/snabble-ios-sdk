//
//  ReceiptsListScreen.swift
//
//
//  Created by Uwe Tilemann on 20.10.23.
//

import SwiftUI
import SnabbleCore
import Combine
import SnabbleAssetProviding

public extension PurchaseProviding {
    var dateString: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(for: date)
    }
}

private struct BadgeCount: ViewModifier {
    let badgeCount: Int
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .badge(badgeCount)
        } else {
            content
        }
    }
}
extension View {
    func badgeCount(_ count: Int) -> some View {
        modifier(BadgeCount(badgeCount: count))
    }
}

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
            .fill((showReadState && !provider.loaded) ? .red : .clear)
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

private struct RefreshAction: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .refreshable {
                    action()
                }
        } else {
            // TODO: we need something here
            content
        }
    }
}

extension View {
    func refreshAction(completion: @escaping () -> Void) -> some View {
        modifier(RefreshAction(action: completion))
    }
}

public struct ReceiptsListScreen: View {
    @ObservedObject var viewModel: PurchasesViewModel
    @ViewProvider(.receiptsEmpty) var emptyView

    public init(model: PurchasesViewModel = .init()) {
        self.viewModel = model
    }

    public var body: some View {
        AsyncContentView(source: viewModel, content: { output in
            VStack {
                List {
                    ForEach(output, id: \.id) { provider in
                        ReceiptsItemView(provider: provider, image: viewModel.imageFor(projectId: provider.projectId))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.actionPublisher.send(provider)
                            }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 16))
                }
                .listStyle(.plain)
                .refreshAction {
                    viewModel.load()
                }
            }
        }, empty: {
            emptyView
        })
        .onAppear {
            viewModel.reset()
        }
        .badgeCount(viewModel.numberOfUnloaded)
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Receipts.title"))
    }
}
