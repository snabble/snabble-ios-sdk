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
    @ObservedObject var viewModel: DynamicViewModel

    public var body: some View {
        HStack(alignment: .top) {
            widget.image
            Text(keyed: widget.text)
                .font(.footnote)
            Spacer()
        }
        .informationStyle()
        .onTapGesture {
            viewModel.actionPublisher.send(.init(widget: widget))
        }
        .shadow(radius: viewModel.configuration.shadowRadius)
    }
}
