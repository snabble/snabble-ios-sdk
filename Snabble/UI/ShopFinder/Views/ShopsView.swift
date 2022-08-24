//
//  ShopsView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SwiftUI

public struct ShopsView: View {
    @ObservedObject public var viewModel: ShopsViewModel

    public init(shops: [ShopProviding]) {
        self.viewModel = ShopsViewModel(shops: shops)
    }

    public var body: some View {
        NavigationView {
            VStack {
                List(viewModel.shops, id: \.id) { shop in
                    ShopCellView(
                        shop: shop,
                        distance: viewModel.distances[shop.id],
                        currentShop: $viewModel.shop
                    )
                }
                .listStyle(PlainListStyle())
                .navigationTitle(Asset.localizedString(forKey: "Snabble.Shop.Finder.title"))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            viewModel.startUpdating()
        }
        .onDisappear {
            viewModel.stopUpdating()
        }
        .navigationViewStyle(.stack)
    }
}

struct ShopFinderView_Previews: PreviewProvider {    
    static var previews: some View {
        ShopsView(shops: [])
    }
}
