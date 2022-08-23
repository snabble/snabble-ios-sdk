//
//  ShopFinderView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SwiftUI

public struct ShopFinderView: View {
    @StateObject public var viewModel = ShopViewModel.default
    @State public var shops: [ShopInfoProvider] = []

    public var body: some View {
        NavigationView {
            VStack {
                List(shops, id: \.id) { shop in
                    NavigationLink {
                        ShopDetailView(shop: shop)
                    } label: {
                        ShopCellView(shop: shop)
                    }
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
        .onChange(of: viewModel.distancesAvailable) { _ in
            shops = viewModel.shops
        }
        .navigationViewStyle(.stack)
    }
}

struct ShopFinderView_Previews: PreviewProvider {    
    static var previews: some View {
        ShopFinderView()
    }
}
