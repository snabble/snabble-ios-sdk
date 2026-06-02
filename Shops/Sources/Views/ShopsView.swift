//
//  ShopsView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SwiftUI
import SnabbleAssetProviding

public struct ShopsView: View {
    @State public var viewModel: ShopsViewModel
    @State private var searchText = ""
    
    var filteredShops: [ShopProviding] {
        if searchText.isEmpty {
            return viewModel.shops
        }
        return viewModel.shops.filter { shop in
            shop.name.localizedCaseInsensitiveContains(searchText) ||
            shop.street.localizedCaseInsensitiveContains(searchText)
        }
    }

    public init(shops: [ShopProviding]) {
        self.viewModel = ShopsViewModel(shops: shops)
    }

    public var body: some View {
        NavigationView {
            List(filteredShops, id: \.id) { shop in
                NavigationLink {
                    ShopView(
                        shop: shop,
                        viewModel: viewModel
                    )
                } label: {
                    ShopCellView(
                        shop: shop,
                        viewModel: viewModel
                    )
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
}

struct ShopFinderView_Previews: PreviewProvider {    
    static var previews: some View {
        ShopsView(shops: [])
    }
}
