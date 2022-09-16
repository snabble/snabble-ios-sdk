//
//  WidgetNavigationView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 15.09.22.
//

import SwiftUI

struct LinkDetailView: View {
    let resource: String
    
    var body: some View {
        if let url = Asset.url(forResource: resource, withExtension: nil) {
            ShowWebView(url: url)
                .padding()
        }
    }
}

public struct WidgetNavigationView: View {
    let widget: WidgetNavigation
    
    public var body: some View {
        NavigationLink {
            LinkDetailView(resource: widget.link)
                .navigationTitle(Asset.localizedString(forKey: widget.text))
        } label: {
            Text(keyed: widget.text)
        }
    }
}
