//
//  ReceiptsListScreen.swift
//
//
//  Created by Uwe Tilemann on 20.10.23.
//

import SwiftUI
import SnabbleCore

public extension PurchaseProviding {
    var dateString: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(for: date)
    }
}

public struct ReceiptsItemView: View {
    public let provider: PurchaseProviding
    
    public var body: some View {
        HStack {
            Image(systemName: "scroll")
            
            VStack(alignment: .leading) {
                Text(provider.name)
                Text(provider.dateString ?? "")
                        .font(.footnote)
            }
            Spacer()
            Text(provider.amount)
                .font(.footnote)
            Image(systemName: "chevron.right")
        }
        .foregroundColor(provider.unloaded ? .primary : .secondary)
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
            content
        }
    }
}

extension View {
    func refreshAction(completion: @escaping () -> Void) -> some View {
        modifier(RefreshAction(action: completion))
    }
}

public struct ReceiptDetailScreen: View {
    public let provider: PurchaseProviding
    
    public var body: some View {
        VStack {
            ReceiptsItemView(provider: provider)
        }
    }
}

public struct ReceiptsListScreen: View {
    @ObservedObject var viewModel: LastPurchasesViewModel

    public init(projectId: Identifier<Project>?) {
        self.viewModel = LastPurchasesViewModel(projectId: projectId)
    }
    
    public var body: some View {
        AsyncContentView(source: viewModel) { output in
            VStack {
                List {
                    ForEach(output, id: \.id) { provider in
                        ReceiptsItemView(provider: provider)
                            .onTapGesture {
                                viewModel.actionPublisher.send(provider)
                            }
                    }
                }
                .listStyle(.plain)
                .refreshAction {
                    viewModel.load()
                }
            }
        }.onAppear {
            viewModel.load()
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Receipts.title"))
    }
}
