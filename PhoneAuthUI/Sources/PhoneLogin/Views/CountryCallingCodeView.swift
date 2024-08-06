//
//  CountryCallingCodeView.swift
//  PhoneLogin
//
//  Created by Uwe Tilemann on 04.05.23.
//

import SwiftUI
import SnabbleAssetProviding
import SnabblePhoneAuth

extension SnabblePhoneAuth.Country {
    var name: String {
        Locale.current.localizedString(forRegionCode: code) ?? "n/a"
    }
}

struct CountryCallingCodeView: View {
    var countries: [SnabblePhoneAuth.Country]
    @Binding var selectedCountry: SnabblePhoneAuth.Country
    @State private var selection: String?
    
    @State private var showMenu = false
    
    var body: some View {
        HStack {
            Button(action: {
                showMenu = true
            }) {
                if let flag = selectedCountry.flagSymbol {
                    Text(flag)
                }
                Text("+\(selectedCountry.callingCode)")
            }
            .foregroundColor(.primary)
        }
        .sheet(isPresented: $showMenu, onDismiss: {}) {
            CountryCallingCodeListView(countries: countries, selection: $selection)
        }
        .onChange(of: selection) { _, value in
            if let value, let country = countries.country(forCode: value) {
                selectedCountry = country
            }
        }
        .onAppear {
            selection = selectedCountry.id
        }
    }
}

private struct CountryCallingCodeListView: View {
    let countries: [SnabblePhoneAuth.Country]
    @Binding var selection: String?
    @State private var searchText = ""
    
    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        ScrollViewReader { proxy in
            NavigationStack {
                List(searchResults, selection: $selection) { value in
                    CountryCallingCodeRow(country: value)
                        .id(value.id)
                        .onTapGesture {
                            selection = value.id
                            dismiss()
                        }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                .navigationTitle(Asset.localizedString(forKey: "Snabble.Account.Country.selection"))
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
        }
    }
    var searchResults: [SnabblePhoneAuth.Country] {
        if searchText.isEmpty {
            return countries.sorted(by: { $0.name < $1.name })
        } else {
            return countries.sorted(by: { $0.name < $1.name }).filter { $0.name.contains(searchText) }
        }
    }
}

private struct CountryCallingCodeRow: View {
    let country: SnabblePhoneAuth.Country

    public var body: some View {
        HStack {
            if let flag = country.flagSymbol {
                Text(flag)
                    .font(.largeTitle)
            }
            VStack(alignment: .leading) {
                Text("+\(country.callingCode)")
                Text(country.name)
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
            Spacer()
        }
        // enables a tap on clear background but requires Spacer() above
        .contentShape(Rectangle())
    }
}
