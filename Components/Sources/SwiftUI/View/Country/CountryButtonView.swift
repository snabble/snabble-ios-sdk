//
//  CountryButtonView.swift
//  PhoneLogin
//
//  Created by Uwe Tilemann on 04.05.23.
//

import SwiftUI
import SnabbleAssetProviding

private struct CountryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.primary)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private extension View {
    func countryButtonStyle() -> some View {
        modifier(CountryButtonModifier())
    }

}

public struct CountryButtonView: View {
    public var countries: [Country]
    
    @Binding public var selectedCountry: Country
    @Binding public var selectedState: Country.State?
        
    @State private var showStateButton = false
    @State private var showCountryMenu = false
    @State private var showStateMenu = false
    
    public init(countries: [Country], 
                selectedCountry: Binding<Country>,
                selectedState: Binding<Country.State?>) {
        self.countries = countries
        self._selectedCountry = selectedCountry
        self._selectedState = selectedState
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                showCountryMenu = true
            }) {
                HStack {
                    if let flagSymbol = selectedCountry.flagSymbol {
                        Text(flagSymbol)
                    }
                    Text(selectedCountry.name)
                    Spacer()
                }
            }
            .countryButtonStyle()
            
            if showStateButton {
                Button(action: {
                    showStateMenu = true
                }) {
                    if let state = selectedState {
                        Text(state.label)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(Asset.localizedString(forKey: "Snabble.User.Country.title"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .countryButtonStyle()
            }
        }
        .sheet(isPresented: $showCountryMenu, onDismiss: {}) {
            CountryListView(countries: countries,
                            selection: .init(get: {
                                selectedCountry
                            }, set: { country in
                                selectedCountry = country ?? selectedCountry
                            })
            )
        }
        .sheet(isPresented: $showStateMenu, onDismiss: {}) {
            CountryStateListView(country: selectedCountry, selection: $selectedState)
        }
        .onChange(of: selectedCountry) { _, country in
            showStateButton = country.states != nil
        }
    }
}

private struct CountryStateListView: View {
    var country: Country
    @Binding var selection: Country.State?
    
    @State private var states: [Country.State] = []

    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selection) {
                ForEach(states.sorted(by: { $0.label < $1.label }), id: \.self) { value in
                    CountryStateRow(state: value)
                        .id(value)
                        .onTapGesture {
                            selection = value
                            dismiss()
                        }
                }
            }
            .onAppear {
                states = country.states ?? []
                proxy.scrollTo(selection, anchor: .center)
            }
       }
    }
}

private struct CountryListView: View {
    let countries: [Country]
    @Binding var selection: Country?
    @State private var searchText = ""
    
    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        ScrollViewReader { proxy in
            NavigationStack {
                List(selection: $selection) {
                    ForEach(searchResults.sorted(by: { $0.name < $1.name }), id: \.self) { value in
                        CountryRow(country: value)
                            .id(value)
                            .onTapGesture {
                                selection = value
                                dismiss()
                            }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                .navigationTitle(Asset.localizedString(forKey: "Snabble.User.Country.title"))
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
        }
    }
    var searchResults: [Country] {
        if searchText.isEmpty {
            return countries.sorted(by: { $0.name < $1.name })
        } else {
            return countries.sorted(by: { $0.name < $1.name }).filter { $0.name.contains(searchText) }
        }
    }
}

private struct CountryStateRow: View {
    let state: Country.State
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(state.label)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

private struct CountryRow: View {
    let country: Country
    
    public var body: some View {
        HStack {
            if let flag = country.flagSymbol {
                Text(flag)
                    .font(.largeTitle)
            }
            VStack(alignment: .leading) {
                Text(country.name)
                Text(country.code)
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}
