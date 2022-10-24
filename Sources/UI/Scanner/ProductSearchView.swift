//
//  ProductSearchView.swift
//  
//
//  Created by Uwe Tilemann on 22.10.22.
//

import SnabbleCore
import SwiftUI
import GRDBQuery

public struct ProductRowView: View {
    var product: Product
    
    @ViewBuilder
    var image: some View {
        if #available(iOS 15.0, *), let urlString = product.imageUrl {
            AsyncImage(url: URL(string: urlString)) { phase in
                if let image = phase.image {
                    image.resizable()
                        .frame(width: 50, height: 50)
                } else {
                    EmptyView()
                }
            }
        } else {
            EmptyView()
        }
    }
    
    public var body: some View {
        HStack {
            image
            VStack(alignment: .leading) {
                if let code = product.codes.first {
                    Text(code.code)
                } else {
                    Text(product.sku)
                }
                Text(product.name)
                    .font(.footnote)
            }
        }
    }
}

public struct ProductSearchView: View {
    @EnvironmentStateObject var viewModel: ProductViewModel
    
    @State private var searchText = ""
    
    public init(viewModel: ProductViewModel) {
        _viewModel = EnvironmentStateObject { _ in
            viewModel
        }
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                TextField("Code", text: $searchText)
                    .frame(minHeight: 32)
                    .padding([.leading, .trailing], 8)
                    .background(Color.themeSearchTextField)
                    .cornerRadius(6)
                    .padding()

                List(viewModel.products, id: \.id) { product in
                    ProductRowView(product: product)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Search Products")
                .listStyle(.plain)
            }
            .onChange(of: searchText) { _ in
                _ = viewModel.productsBy(prefix: searchText)
            }
        }
    }
}

extension Color {
    static var themeSearchTextField: Color {
        return Color(red: 220.0 / 255.0, green: 230.0 / 255.0, blue: 230.0 / 255.0, opacity: 1.0)
    }
}
