//
//  ShopFinderView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SwiftUI

public struct ShopFinderView: View {
    @EnvironmentObject var model: ShopViewModel
    
    public init() {}

    public var body: some View {
        NavigationView {
            VStack {
                List(model.shops, id: \.id) { shop in
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
        .navigationViewStyle(.stack)
    }
}

struct ShopFinderView_Previews: PreviewProvider {    
    static var previews: some View {
        ShopFinderView().environmentObject(ShopViewModel.shared)
    }
}
