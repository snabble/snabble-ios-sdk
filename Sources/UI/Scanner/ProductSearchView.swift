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

struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.secondarySystemBackground)
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Code", text: $searchText)
            }
            .foregroundColor(.secondaryLabel)
            .padding(.leading, 13)
        }
        .frame(height: 40)
        .cornerRadius(12)
        .padding()
    }
    
}

public struct ProductSearchView: View {
    @EnvironmentStateObject var viewModel: ProductModel
    
    @State private var searchText = ""
    
    public init(viewModel: ProductModel) {
        _viewModel = EnvironmentStateObject { _ in
            viewModel
        }
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                SearchBar(searchText: $searchText)

                List(viewModel.products, id: \.id) { product in
                    ProductRowView(product: product)
                        .onTapGesture {
                            if let code = product.codes.first {
                                _ = viewModel.productBy(code: code.code)
                            }
                        }
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
