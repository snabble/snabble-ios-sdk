//
//  ShopsView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

/// A searchable list of shops without its own navigation container.
///
/// Use it as the sidebar of a `NavigationSplitView` and show the selected shop in the detail column.
public struct ShopsListView: View {
    let viewModel: ShopsViewModel
    @Binding var selection: Identifier<Shop>?

    @State private var searchText = ""

    public init(viewModel: ShopsViewModel, selection: Binding<Identifier<Shop>?>) {
        self.viewModel = viewModel
        self._selection = selection
    }

    var filteredShops: [ShopProviding] {
        if searchText.isEmpty {
            return viewModel.shops
        }
        return viewModel.shops.filter { shop in
            shop.name.localizedCaseInsensitiveContains(searchText) ||
            shop.street.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        List(filteredShops, id: \.id, selection: $selection) { shop in
            NavigationLink(value: shop.id) {
                ShopCellView(shop: shop, viewModel: viewModel)
            }
        }
        .searchable(text: $searchText, prompt: "Search shops")
        .listStyle(.plain)
        .onAppear {
            viewModel.startUpdating()
        }
        .onDisappear {
            viewModel.stopUpdating()
        }
    }
}

/// The shop list with the selected shop as detail. Shown side by side in regular width,
/// collapsed to a navigation stack in compact width.
public struct ShopsView: View {
    @State public var viewModel: ShopsViewModel
    @State private var selection: Identifier<Shop>?

    public init(shops: [ShopProviding]) {
        self.viewModel = ShopsViewModel(shops: shops)
    }

    public var body: some View {
        NavigationSplitView {
            ShopsListView(viewModel: viewModel, selection: $selection)
        } detail: {
            ShopsDetailView(viewModel: viewModel, selection: selection)
        }
    }
}

/// The detail column for a selected shop, or a placeholder when nothing is selected.
public struct ShopsDetailView: View {
    let viewModel: ShopsViewModel
    let selection: Identifier<Shop>?

    public init(viewModel: ShopsViewModel, selection: Identifier<Shop>?) {
        self.viewModel = viewModel
        self.selection = selection
    }

    public var body: some View {
        if let shop = viewModel.shops.first(where: { $0.id == selection }) {
            ShopView(shop: shop, viewModel: viewModel)
                // ShopView keeps per-shop @State, so give each shop its own identity.
                .id(shop.id)
        } else {
            ContentUnavailableView {
                Label {
                    Text(keyed: "Snabble.Shop.Finder.title")
                } icon: {
                    Image(systemName: "storefront")
                }
            }
        }
    }
}

struct ShopFinderView_Previews: PreviewProvider {
    static var previews: some View {
        ShopsView(shops: [])
    }
}
