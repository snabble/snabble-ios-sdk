//
//  ShopFinderView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SwiftUI

public struct ShopFinderView: View {
    @ObservedObject public var model: ProjectModel
    
    public init(model: ProjectModel) {
        self.model = model
    }

    public var body: some View {
        NavigationView {
            VStack {
                List(model.project.shops, id: \.id) { shop in
                    NavigationLink {
                        ShopDetailView(shop: shop)
                    } label: {
                        ShopCellView(shop: shop, distance: model.formattedDistance(for: shop))
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Shops")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ShopFinderView_Previews: PreviewProvider {    
    static var previews: some View {
        ShopFinderView(model: ProjectModel.shared)
    }
}
