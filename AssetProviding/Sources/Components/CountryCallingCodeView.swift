//
//  CountryCallingCodeView.swift
//  PhoneLogin
//
//  Created by Uwe Tilemann on 04.05.23.
//

import SwiftUI

public struct CountryCallingCodeView: View {
    var countries: [CallingCode]
    @Binding var selectedCountry: CallingCode
    @State private var selection: String?
    
    @State private var showMenu = false
    
    public init(countries: [CallingCode], selectedCountry: Binding<CallingCode>) {
        self.countries = countries
        self._selectedCountry = selectedCountry
    }
    public var body: some View {
        HStack {
            Button(action: {
                showMenu = true
            }) {
                if let flag = selectedCountry.flagSymbol {
                    Text(flag)
                }
                Text("+\(selectedCountry.code)")
            }
            .foregroundColor(.primary)
        }
        .sheet(isPresented: $showMenu, onDismiss: {}) {
            CountryCallingCodeListView(countries: countries, selection: $selection)
        }
        .onChange(of: selection) { _, value in
            if let value, let country = countries.callingCode(forId: value) {
                selectedCountry = country
            }
        }
        .onAppear {
            selection = selectedCountry.id
        }
    }
}

private struct CountryCallingCodeListView: View {
    let countries: [CallingCode]
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
    var searchResults: [CallingCode] {
        if searchText.isEmpty {
            return countries.sorted(by: { $0.name < $1.name })
        } else {
            return countries.sorted(by: { $0.name < $1.name }).filter { $0.name.contains(searchText) }
        }
    }
}

private struct CountryCallingCodeRow: View {
    let country: CallingCode

    public var body: some View {
        HStack {
            if let flag = country.flagSymbol {
                Text(flag)
                    .font(.largeTitle)
            }
            VStack(alignment: .leading) {
                Text("+\(country.code)")
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
