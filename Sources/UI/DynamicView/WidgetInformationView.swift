//
//  WidgetInformationView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

private struct InformationStyle: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            content
                .padding(12)
        }
        .background(Color.systemBackground)
        .cornerRadius(8)
    }
}

extension View {
    func informationStyle() -> some View {
        modifier(InformationStyle())
    }
}

public struct WidgetInformationView: View {
    let widget: WidgetInformation
    let configuration: DynamicViewConfiguration

    public var body: some View {
        HStack(spacing: 12) {
            widget.image
            Text(keyed: widget.text)
                .font(.subheadline)
        }
        .informationStyle()
        .shadow(radius: configuration.shadowRadius)
    }
}
