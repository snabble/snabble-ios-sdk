//
//  BarcodeSearchView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 18.06.24.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
import SnabbleUI

struct BarcodeSearchRowView: View {
    let product: Product
    @Binding var searchText: String
    
    @State private var codeString: LocalizedStringKey = ""
    
    var code: String {
        let codeEntry = product.codes.filter { $0.code.hasPrefix(self.searchText) }.first ?? product.codes.first!
        
        return codeEntry.code
    }
    var body: some View {
        VStack(alignment: .leading) {
            Text(codeString)
            Text(product.name)
                .font(.caption)
        }
        .padding(.horizontal)
        .containerRelativeFrame(.horizontal, alignment: .leading)
        .contentShape(Rectangle())
        .task {
            update()
        }
        .onChange(of: searchText) {
            update()
        }
    }
    private func update() {
        if code.hasPrefix(searchText) {
            let index = code.index(code.startIndex, offsetBy: searchText.count)
            codeString = LocalizedStringKey("**\(searchText)**" + code[index...])
        } else {
            codeString = LocalizedStringKey(code)
        }
    }
}

extension SnabbleCore.Product: Swift.Identifiable, Equatable, Hashable {
    public var id: String {
        sku
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: SnabbleCore.Product, rhs: SnabbleCore.Product) -> Bool {
        lhs.sku == rhs.sku && lhs.type == rhs.type
    }
}

struct BarcodeSearchView: View {
    let model: BarcodeManager
    let completion: ((String, ScanFormat?, String?) -> Void)
    
    @State var selection: SnabbleCore.Product?
    @State private var searchText = ""
    @State private var showSearch: Bool = false
    @State private var products = [SnabbleCore.Product]()
    
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    @ViewBuilder
    var content: some View {
        if searchResults.isEmpty {
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Text(Asset.localizedString(forKey: "Snabble.Scanner.enterBarcode"))
                    if !searchText.isEmpty {
                        SecondaryButtonView(title: Asset.localizedString(forKey: "Snabble.Scanner.addCodeAsIs", arguments: self.searchText), onAction: {
                            completion(searchText, nil, nil)
                        })
                    }
                }
                Spacer()
            }
        } else {
            List(searchResults, selection: $selection) { value in
                BarcodeSearchRowView(product: value, searchText: $searchText)
                    .id(value.id)
                    .onTapGesture {
                        selection = value
                    }
            }
            .listStyle(.plain)
            .onChange(of: selection) {
                if let selection {
                    let codeEntry = selection.codes.filter { $0.code.hasPrefix(self.searchText)
                    }.first ?? selection.codes.first!
                    completion(codeEntry.code, nil, codeEntry.template)
                }
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            content
                .searchable(text: $searchText,
                            isPresented: $showSearch,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: Text(Asset.localizedString(forKey: "Snabble.Scanner.enterBarcode")))
                .onChange(of: showSearch) {
                    if !showSearch {
                        dismiss()
                    }
                }
                .navigationTitle(Asset.localizedString(forKey: "Snabble.Scanner.enterBarcode"))
                .navigationBarTitleDisplayMode(.inline)
        }
        .keyboardType(.numberPad)
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showSearch = true
        }
    }
    
    var searchResults: [SnabbleCore.Product] {
        guard !searchText.isEmpty else {
            return []
        }
        let products = model.productProvider.productsBy(prefix: searchText,
                                                        filterDeposits: true,
                                                        templates: model.project.searchableTemplates,
                                                        shopId: model.shop.id)
        return removeDuplicates(products).sorted { prod1, prod2 in
            let code1 = prod1.codes.filter { $0.code.hasPrefix(searchText) }.first ?? prod1.codes.first!
            let code2 = prod2.codes.filter { $0.code.hasPrefix(searchText) }.first ?? prod2.codes.first!
            return code1.code < code2.code
        }
    }
    
    private func removeDuplicates(_ products: [Product]) -> [Product] {
        var skusAdded = [String: Bool]()
        
        return products.filter {
            skusAdded.updateValue(true, forKey: $0.sku) == nil
        }
    }
}
